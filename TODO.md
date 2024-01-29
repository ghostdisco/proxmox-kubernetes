
[/] 0.1
    [/] get kubespray working
        [ ] bugs
            [ ] during vm-kubespray-host.tf -> setup_kubespray.sh, push the fcc private key to the kubespray host as id_rsa (or using an ssh config file to specify using fcc key)
            [ ] the id_rsa file that made its way to the kubespray_data folder on the kubespray host was missing the private key header and footer (--BEGIN PRIVATE KEY--)
            [ ] below may not be necessary if previous step fixes issue

                [ ] add the worker server's fingerprints to the 
                [ ] remove the following substring in the first line of the nodes' /root/.ssh/authorized_keys file:
                    'no-port-forwarding,no-agent-forwarding,no-X11-forwarding,command="echo 'Please login as the user \"ubuntu\" rather than the user \"root\".';echo;sleep 10;exit 142" '
                    
                    this should leave the following:
                    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDLpY0AVkzcyaNFHELPUzLZcMY+9sb8a/ptig+qaC06p/cxjvadVLRe8Z7VODHaaZY3P3xOB9KQAFLiMKxWLPl0fKbD/YIGimBk+ytIVeENshJcr6ohnMixuqrhYi8N8kIBLu9LQnd6gT/GEsEz+0K8HQHAsKSFQ/Viy9oxMP+VltOc2vneTc5/TAoK/oWfZmy1x6CseCVchI+Ik8uKL+N8NJqI5JHDlezPxhfPNzeldQcap4/LgQxUDyPl1kc+2zB3gVT4/XTg07jPAo6GHqr0Ixo1UbQH4wWUp0R8oZNQeNUARZ9ackQPQLcz4BkOlRC/5kTJusS4HaqAFNc6/1MvQmDC/v8ihOuB3ok/VvuvbU7A4uKm+Om85iKrbQlguhnipW5dQ2PNTwPmbo1YE5gDpOwQC0RFP+ggYEV9Rz/IP54f24tyf1tWUI+//7tY2ZyicXlElLnX7oOU0N96Pkqytnu6jCSvuaHaaYF99VpmrjDwPQepLes1UzrUMf1ubiIJrOcrEohJBVv4SGeiphtmEH1PPrZCirA6hR52Sr8o4U6ohbw0cFr7mSBFDHmnP6yaschOQ66s+6AhTT2oCha/LJFr9J1A6m/IT0ecbw9DmcSJ1C5GESiiHXmdl449SBGHpB4feEKkIPlysgG1mqeOTZykBBdYbnM5jgt5xDOWCQ== k8s-admin@cluster.local

[ ] v1.0
    [ ] fix vmids

[ ] icebox
    [ ] create clone of khanhphhub/kubespray:v2.22.0 image in own registry to replace kubespray_image default value

