create or replace type TStrings is table of varchar2(4000);
/
create or replace function WebBrowser( url varchar2 ) return TStrings pipelined is
--
-- BASIC PL/SQL WEB BROWSER TEMPLATE
-- supports http, https and proxy servers

        -- fixed constants
        C_NO_PROXY_FOR  constant varchar2(4000) := 'localhost';
        C_WALLET        constant varchar2(4000) := 'file:/etc/ORACLE/WALLETS/oracle/';
        C_WALLET_PASS   constant varchar2(4000) := '<wallet password goes here>';

        -- Proxy settings that can be made arguments in the WebBrowser() call
        proxyServer     varchar2(20) := NULL
        -- not all proxy servers use authentication, but many corporate proxies do, in
        -- which case you need to specify your auth details here
        -- (make it nulls if not applicable)
        proxyUser       varchar2(50) := '<proxy username goes here>';
        proxyPass       varchar2(50) := '<proxy password goes here>';

        -- our local variables
        proxyURL        varchar2(4000);
        request         UTL_HTTP.req;
        response        UTL_HTTP.resp;
        buffer          varchar2(4000);
        endLoop         boolean;
begin
        -- our "browser" settings
        PIPE ROW( 'Setting browser configuration' );
        UTL_HTTP.set_response_error_check( TRUE );
        UTL_HTTP.set_detailed_excp_support( TRUE );
        UTL_HTTP.set_cookie_support( TRUE );
        UTL_HTTP.set_transfer_timeout( 30 );
        UTL_HTTP.set_follow_redirect( 3 );
        UTL_HTTP.set_persistent_conn_support( TRUE );

        -- set wallet for HTTPS access
        PIPE ROW( 'Wallet set to '||C_WALLET );
        UTL_HTTP.set_wallet( C_WALLET, C_WALLET_PASS );

        -- configure for proxy access
        if proxyServer is not NULL then
                PIPE ROW( 'Proxy Server is '||proxyServer );
                proxyURL := 'http://'||proxyServer;

                if (proxyUser is not NULL) and (proxyPass is not NULL) then
                        proxyURL := REPLACE( proxyURL, 'http://',  'http://'||proxyUser||':'||proxyPass||'@' );
                        PIPE ROW( 'Proxy URL modified to include proxy user name and password' );
                end if;

                PIPE ROW( 'Proxy URL is '|| REPLACE(proxyURL,proxyPass,'*****') );
                UTL_HTTP.set_proxy( proxyURL, C_NO_PROXY_FOR );
        end if;

        PIPE ROW( 'HTTP: GET '||url );
        request := UTL_HTTP.begin_request( url, 'GET', UTL_HTTP.HTTP_VERSION_1_1 );

        -- set HTTP header for the GET
        UTL_HTTP.set_header( request, 'User-Agent', 'Mozilla/4.0 (compatible)' );

        -- get response to the GET from web server
        response := UTL_HTTP.get_response( request );

        -- pipe the response as rows
        endLoop := false;
        loop
                exit when endLoop;

                begin
                        UTL_HTTP.read_line( response, buffer, TRUE );
                        if (buffer is not null) and length(buffer)>0 then
                                PIPE ROW( buffer );
                        end if;
                exception when UTL_HTTP.END_OF_BODY then
                        endLoop := true;
                end;

        end loop;
        UTL_HTTP.end_response( response );

        return;

exception when OTHERS then
        PIPE ROW( SQLERRM );
end;
/
show errors
