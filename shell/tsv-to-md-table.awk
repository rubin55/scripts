BEGIN {
  FS="\t"
} 

{
  n=(NF>n?NF:n); 

  for(i=1;i<=NF;i++) {
    if(length($i)>w[i]) 
    w[i]=length($i)
  } 
  rows[NR]=$0
} 

END {
  for(r=1;r<=NR;r++) {
    split(rows[r],f,FS); 
    printf("|"); 

    for(i=1;i<=n;i++) {
      printf(" %-*s |", w[i], f[i])
    } 
    printf("\n"); 
    if(r==1) {
      printf("|"); 
      for(i=1;i<=n;i++) {
        dash=""; 
        for(j=1;j<=w[i];j++) 
        dash=dash"-"; 
        printf(" %s |", dash)
      } 
      printf("\n")
    }
  }
}
