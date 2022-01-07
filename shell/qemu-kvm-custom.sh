#!/bin/sh
exec /usr/bin/qemu-kvm -no-kvm-pit -no-kvm-irqchip -tdf "$@"


