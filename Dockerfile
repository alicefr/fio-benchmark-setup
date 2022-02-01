FROM fedora:35

RUN dnf install -y fio python3 && dnf clean all
RUN mkdir -p /output
COPY ./fio-jobs /fio-jobs
WORKDIR output

CMD ["fio", "/fio-jobs/*", "--output fio-job.log"]
