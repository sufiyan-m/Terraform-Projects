# Terraform Projects

## Project # 1 

Create an EC2 instance, deploy it on a custom VPC on a custom subnet and assign it a public IP address so that we can SSH into it to connect and make some changes accordingly.
The idea is to setup a web server so that we can handle the web traffic. Following are the steps that will be followed:

1. Create VPC
2. Create Internet Gateway
3. Create a Custom Route Table
4. Create a subnet 
5. Associate a subnet with the Route Table
6. Create security group to allow port 22, 80, 443
7. Create a network interface with an ip in the subnet that was created in step 4
8. Assign an elastic ip address to the network interface created in step 7
9. Create an ubuntu server and install/enable apache2
