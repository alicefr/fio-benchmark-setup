CONTAINER_RUNTIME ?= docker
IMAGE=fio
DEVICE_IN_CONTAINER ?= device-to-test
TIME_RUNNING_TEST ?= 300
TEST_FLAVOR ?= write,read,randread,randwrite
BLOCKSIZE ?= 4k,1m
FIO_JOBS_DIR=fio-jobs

fio-image:
	$(CONTAINER_RUNTIME) build -t $(IMAGE) .

generate-fio-jobs:
	mkdir -p fio-jobs
	$(CONTAINER_RUNTIME) run -ti --security-opt label=disable \
	--user $(shell id -u) \
	-v $(PWD)/$(FIO_JOBS_DIR):/fio-jobs \
	-w /fio-jobs \
	--hostname fio \
	--entrypoint genfio \
	fio \
	-d /dev/$(DEVICE_IN_CONTAINER) -r $(TIME_RUNNING_TEST) -m $(TEST_FLAVOR) -b $(BLOCKSIZE) -s -x fio

fio-containerdisk:
	./create-containerdisk-fio.sh $(IMAGE)

clean:
	rm -rf $(OUTPUT_DIR) $(FIO_JOBS_DIR)
