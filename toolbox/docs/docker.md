# Access host from inside container

    http://host.docker.internal:<port>

# Cleanup

    docker system prune -a --volumes

# Enter the Docker VM on Docker for Mac/Windows

    docker run -it --privileged --pid=host debian nsenter -t 1 -m -u -n -i sh

# Show running containers without truncating labels

    docker ps -a --no-trunc

# Build docker image for Raspberry Pi

Register Multiarch Build Agent on Dev Machine

    docker run --rm --privileged multiarch/qemu-user-static:register --reset

Adjust Base Image in Dockerfile

    FROM multiarch/alpine:armhf-edge

Build Image and export it

    docker build -t myProject:arm .
    docker save -o myProject.tar.gz myProject

Import it on the Pi

    scp myProject.tar.gz user@host:/path/to/dir
    docker load -i myProject.tar.gz

Autostart container

    docker run --restart always -d -p <port-of-host>:<port-inside-container> myProject

Check if image exists

    docker manifest inspect <registry>/<repository>[:tag]
    # e.g. docker manifest inspect my-region.amazonaws.com/docker/library/node:20.12-alpine
