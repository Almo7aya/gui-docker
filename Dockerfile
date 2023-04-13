FROM manjarolinux/base

RUN pacman -Sy --noconfirm archlinux-keyring
RUN pacman -Syyu --noconfirm
RUN pacman -S --noconfirm \
    i3status \
    i3-wm \
    git \
    sudo \
    net-tools \
    python3 \
    rxvt-unicode \
    supervisor \
    ttf-dejavu \
    x11vnc \
    xorg-server \
    xorg-apps \
    xorg-server-xvfb \
    xorg-xinit

# for the VNC connection
EXPOSE 5900

EXPOSE 8083
# for the browser VNC client
EXPOSE 5901
# Use environment variable to allow custom VNC passwords
ENV VNC_PASSWD=123456

# Install VNC. Requires net-tools, python and python-numpy
RUN git clone --branch v1.2.0 --single-branch https://github.com/novnc/noVNC.git /opt/noVNC
RUN git clone --branch v0.9.0 --single-branch https://github.com/novnc/websockify.git /opt/noVNC/utils/websockify
RUN ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html

# Add menu entries to the container
# RUN echo "?package(bash):needs=\"X11\" section=\"DockerCustom\" title=\"Xterm\" command=\"xterm -ls -bg black -fg white\"" >> /usr/share/menu/custom-docker && update-menus

# Set timezone to UTC
RUN ln -snf /usr/share/zoneinfo/UTC /etc/localtime && echo UTC > /etc/timezone

# Add in a health status
HEALTHCHECK --start-period=10s CMD bash -c "if [ \"`pidof -x Xtigervnc | wc -l`\" == "1" ]; then exit 0; else exit 1; fi"

# Add in non-root user
ARG USER=dockerUser

ENV UID_OF_DOCKERUSER 1000

RUN useradd -m -s /bin/bash -N -u ${UID_OF_DOCKERUSER} dockerUser && \
    echo "dockerUser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers && \
    chmod 0440 /etc/sudoers && \
    chmod g+w /etc/passwd && \
    chown -R dockerUser:users /home/dockerUser && \
    chown dockerUser:users /opt

USER dockerUser

# Copy various files to their respective places
COPY --chown=dockerUser:users container_startup.sh /opt/container_startup.sh
COPY --chown=dockerUser:users x11vnc_entrypoint.sh /opt/x11vnc_entrypoint.sh
# Subsequent images can put their scripts to run at startup here
RUN mkdir /opt/startup_scripts

# ENTRYPOINT ["/opt/container_startup.sh"]
CMD ["/usr/bin/supervisord"]

