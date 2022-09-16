# Setup ssh key for CI machines

function setup_ssh_config_if_needed() {
  config="\nHost gitlab.protontech.ch\nAddKeysToAgent yes\nUseKeychain yes\nIdentityFile ~/.ssh/id_rsa_ci\n"
  file=~/.ssh/config
  if [ -f $file ]; then
    if ! grep -q "id_rsa_ci" $file; then
      echo $config >> $file
    fi
  else 
    echo $config >> $file
  fi
}

function set_up_ssh_key() {
  base64 -D -o ~/.ssh/id_rsa_ci <<< $id_rsa_base64_ci
  setup_ssh_config_if_needed
  chmod 600 ~/.ssh/id_rsa_ci
}

if [[ ! -z "${id_rsa_base64_ci}" ]]; then
  set_up_ssh_key
fi