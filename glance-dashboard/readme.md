# Glance Dashboard Setup

This folder contains scripts and configuration to quickly set up the Glance Dashboard using Docker Compose.

## Quick Start

### Windows

1. Run `install.bat`.
2. Edit the following files as prompted:
   -  `docker-compose.yml` (configure ports, volumes, etc.)
   -  `config/home.yml` (customize widgets and layout)
   -  `config/glance.yml` (change theme or add pages)
3. When prompted, press Enter to continue after editing configuration.
4. The dashboard will be available at [http://localhost:4403](http://localhost:4403).

### Linux/macOS

1. Run `install.sh`.
2. Edit the same files as above when prompted.
3. Press Enter to continue after editing configuration.
4. The dashboard will be available at [http://localhost:4403](http://localhost:4403).

## Notes

-  The install scripts automatically fetch the latest Glance Docker Compose template and adjust the default port mapping to 4403:8080.
-  Make sure Docker and Docker Compose are installed on your system.

## Resources

-  [Glance Dashboard GitHub](https://github.com/glanceapp/glance)
