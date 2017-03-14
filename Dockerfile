FROM registry.cloud.com:5000/rhel7.3:latest

USER 0

ADD scheduledjob/*  /opt/
RUN useradd -u 1000 jober && \
    chown -R 1000:1000 /opt/

USER 1000
CMD ["/bin/bash"]
