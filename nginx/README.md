

# Example Nginx Docker Container

Nginx server example with automatic reloading, Let's Encrypt SSL support, multiple virtual hosts.

## Virtual Hosts Support

This setup supports the configuration of multiple virtual hosts using Nginx's server blocks. The templates directory (`./templates`) contains a default configuration file (`default.conf.template`) that serves the `index.html` file by default and uses the domain specified in the `DEFAULT_DOMAIN` environment variable, which must be defined in the `.env` file.

To add more virtual hosts:
1. Create additional configuration templates with custom server blocks in the `./templates` directory.
2. Each template can define different domains and server settings, allowing the Nginx server to handle multiple websites or applications on the same server.

## SSL support

This setup support 

## How to Use

1. **Set Up Environment Variables**:
   Create a `.env` file in the root of your project and define the following variables:
   ```env
   TIMEZONE=Your/Timezone

**Important**: If you modify the .env file and/or modify the config templates, and the nginx container is up and running, you must force recreate the container:

   ```docker compose up -d --force-recreate