# Dockerized OpenSCAD renderer — programmatic mesh + image rendering.
#
# Contains ONLY OpenSCAD + our scripts (source is bind-mounted at run time, so editing a
# .scad needs no rebuild). xvfb is added so OpenSCAD can export PNG snapshots headlessly
# (PNG output needs a GL context; xvfb provides a virtual framebuffer).
#
# Override the OpenSCAD version with:  docker build --build-arg OPENSCAD_TAG=... .
# Pinned to a dated nightly snapshot for reproducibility (see hub.docker.com/r/openscad/openscad/tags).
ARG OPENSCAD_TAG=bookworm.2026-01-19
FROM openscad/openscad:${OPENSCAD_TAG}

USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends xvfb xauth \
    && rm -rf /var/lib/apt/lists/*

# Shared library search path. Mount shared .scad include dirs here at run time
# (e.g. the gridfinity-rebuilt library) so `include <...>` resolves.
ENV OPENSCADPATH=/libs

COPY render.sh   /usr/local/bin/render
COPY snapshot.sh /usr/local/bin/snapshot
RUN chmod +x /usr/local/bin/render /usr/local/bin/snapshot

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/render"]
