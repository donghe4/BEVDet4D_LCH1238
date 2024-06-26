# To run the container from dockerhub
docker run -it --rm \
        --gpus all \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        -v /data:/data \
        -v ./:/workspace \
        --privileged \
        --shm-size=128g \
        --network=host \
        --name donghe_bevdet_trt \
        ytwanghaoyu/bevdet:bevdet-6c75bb4e-fix