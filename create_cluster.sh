#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

source $SCRIPT_DIR/lib/shared/functions.sh

source $SCRIPT_DIR/lib/create/parse_arguments.sh

source $SCRIPT_DIR/lib/create/create_firewall.sh

source $SCRIPT_DIR/lib/create/create_network.sh

source $SCRIPT_DIR/lib/create/create_cloud_init_config.sh

source $SCRIPT_DIR/lib/create/create_instances.sh

source $SCRIPT_DIR/lib/create/deploy_k3s.sh

source $SCRIPT_DIR/lib/create/deploy_cloud_controller_manager.sh

source $SCRIPT_DIR/lib/create/deploy_csi_driver.sh

source $SCRIPT_DIR/lib/create/deploy_system_upgrade_controller.sh

echo "Finished building k3s cluster."
