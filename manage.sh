#!/bin/bash

# Change to the script's directory
cd "$(dirname "$0")"

IMAGE_NAME="${LAYA_DOCKER_REPO:-vinaybalamuru/laya}"
IMAGE_TAG="${LAYA_DOCKER_TAG:-cuda}"
IMAGE_CPU_TAG="${LAYA_DOCKER_CPU_TAG:-cpu}"
TORCH_INDEX="${LAYA_TORCH_INDEX:-cu130}"
TORCH_VERSION="${LAYA_TORCH_VERSION:-2.14.0}"
COMPOSE_CUDA="docker-compose/docker-compose.yml"
COMPOSE_CPU="docker-compose/docker-compose.cpu.yml"
IS_INTERACTIVE=0

show_menu() {
    clear
    echo "================================================="
    echo "       Laya Docker Stack Management (CUDA & CPU)"
    echo "================================================="
    echo "Targets: ${IMAGE_NAME}:${IMAGE_TAG} (CUDA) | ${IMAGE_NAME}:${IMAGE_CPU_TAG} (CPU)"
    echo ""
    echo "  -- CUDA (GPU) Actions --"
    echo "  1. Build CUDA Image"
    echo "  2. Push CUDA Image to Docker Hub"
    echo "  3. Start CUDA Server (docker-compose up -d)"
    echo "  4. Run CUDA Quickstart"
    echo "  5. View CUDA Logs"
    echo "  6. Test CUDA GPU in Container"
    echo ""
    echo "  -- CPU-Only Actions --"
    echo "  7. Build CPU Image"
    echo "  8. Push CPU Image to Docker Hub"
    echo "  9. Start CPU Server (docker-compose.cpu up -d)"
    echo " 10. Run CPU Quickstart"
    echo " 11. View CPU Logs"
    echo ""
    echo "  -- Stack Control --"
    echo " 12. Stop All Stacks"
    echo " 13. Exit"
    echo ""
    read -p "Enter your choice (1-13): " choice

    IS_INTERACTIVE=1
    case $choice in
        1) build_cuda ;;
        2) push_cuda ;;
        3) start_cuda ;;
        4) run_quickstart_cuda ;;
        5) view_logs_cuda ;;
        6) test_cuda ;;
        7) build_cpu ;;
        8) push_cpu ;;
        9) start_cpu ;;
        10) run_quickstart_cpu ;;
        11) view_logs_cpu ;;
        12) stop_all ;;
        13) exit 0 ;;
        *)
            echo ""
            echo "Invalid choice. Please try again."
            read -p "Press enter to continue..."
            show_menu
            ;;
    esac
}

pause_and_menu() {
    if [ "$IS_INTERACTIVE" -eq 1 ]; then
        echo ""
        read -p "Press enter to continue..."
        show_menu
    fi
}

build_cuda() {
    echo ""
    echo "Building CUDA image (${IMAGE_NAME}:${IMAGE_TAG})..."
    docker build \
        --build-arg TORCH_INDEX="$TORCH_INDEX" \
        --build-arg TORCH_VERSION="$TORCH_VERSION" \
        -t "${IMAGE_NAME}:${IMAGE_TAG}" \
        .
    if [ $? -eq 0 ]; then
        echo "CUDA Image built successfully: ${IMAGE_NAME}:${IMAGE_TAG}"
    else
        echo "Build failed!"
    fi
    pause_and_menu
}

build_cpu() {
    echo ""
    echo "Building CPU image (${IMAGE_NAME}:${IMAGE_CPU_TAG})..."
    docker build \
        --build-arg TORCH_INDEX="cpu" \
        --build-arg TORCH_VERSION="$TORCH_VERSION" \
        -t "${IMAGE_NAME}:${IMAGE_CPU_TAG}" \
        .
    if [ $? -eq 0 ]; then
        echo "CPU Image built successfully: ${IMAGE_NAME}:${IMAGE_CPU_TAG}"
    else
        echo "Build failed!"
    fi
    pause_and_menu
}

push_cuda() {
    echo ""
    echo "Pushing ${IMAGE_NAME}:${IMAGE_TAG} to Docker Hub..."
    docker push "${IMAGE_NAME}:${IMAGE_TAG}"
    pause_and_menu
}

push_cpu() {
    echo ""
    echo "Pushing ${IMAGE_NAME}:${IMAGE_CPU_TAG} to Docker Hub..."
    docker push "${IMAGE_NAME}:${IMAGE_CPU_TAG}"
    pause_and_menu
}

run_quickstart_cuda() {
    echo ""
    echo "Running CUDA quickstart via Docker Compose..."
    docker compose --env-file docker-compose/.env -f "$COMPOSE_CUDA" run --rm laya
    pause_and_menu
}

run_quickstart_cpu() {
    echo ""
    echo "Running CPU quickstart via Docker Compose..."
    docker compose --env-file docker-compose/.env -f "$COMPOSE_CPU" run --rm laya
    pause_and_menu
}

start_cuda() {
    echo ""
    echo "Starting laya-serve (CUDA) in background..."
    docker compose --env-file docker-compose/.env -f "$COMPOSE_CUDA" up -d laya-serve
    pause_and_menu
}

start_cpu() {
    echo ""
    echo "Starting laya-serve-cpu (CPU) in background..."
    docker compose --env-file docker-compose/.env -f "$COMPOSE_CPU" up -d laya-serve
    pause_and_menu
}

stop_all() {
    echo ""
    echo "Stopping all stacks..."
    docker compose --env-file docker-compose/.env -f "$COMPOSE_CUDA" down 2>/dev/null
    docker compose --env-file docker-compose/.env -f "$COMPOSE_CPU" down 2>/dev/null
    echo "All stacks stopped."
    pause_and_menu
}

view_logs_cuda() {
    echo ""
    echo "Streaming CUDA logs (Press Ctrl+C to exit)..."
    docker compose --env-file docker-compose/.env -f "$COMPOSE_CUDA" logs -f laya-serve
    pause_and_menu
}

view_logs_cpu() {
    echo ""
    echo "Streaming CPU logs (Press Ctrl+C to exit)..."
    docker compose --env-file docker-compose/.env -f "$COMPOSE_CPU" logs -f laya-serve
    pause_and_menu
}

test_cuda() {
    echo ""
    echo "Testing CUDA availability inside container (${IMAGE_NAME}:${IMAGE_TAG})..."
    docker run --rm --gpus all "${IMAGE_NAME}:${IMAGE_TAG}" python -c \
        'import torch; assert torch.cuda.is_available(), "CUDA unavailable"; print("GPU detected:", torch.cuda.get_device_name(0)); print("CUDA tensor:", torch.ones(1, device="cuda").cpu())'
    pause_and_menu
}

# CLI Argument Handler
case "${1:-}" in
    build|build-cuda)
        build_cuda
        ;;
    build-cpu)
        build_cpu
        ;;
    push|push-cuda)
        push_cuda
        ;;
    push-cpu)
        push_cpu
        ;;
    start|up|start-cuda)
        start_cuda
        ;;
    start-cpu|up-cpu)
        start_cpu
        ;;
    stop|down)
        stop_all
        ;;
    run|run-cuda)
        run_quickstart_cuda
        ;;
    run-cpu)
        run_quickstart_cpu
        ;;
    logs|logs-cuda)
        view_logs_cuda
        ;;
    logs-cpu)
        view_logs_cpu
        ;;
    test)
        test_cuda
        ;;
    *)
        show_menu
        ;;
esac
