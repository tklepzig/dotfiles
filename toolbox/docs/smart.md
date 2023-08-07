# Test external HDD with smartctl

Install

    sudo apt install smartmontools

Start Test

    sudo smartctl -t long -d sat /dev/sda -T permissive

Wait for it...

After its completion, see the results

    sudo smartctl -l selftest -d sat /dev/sda -T permissive
