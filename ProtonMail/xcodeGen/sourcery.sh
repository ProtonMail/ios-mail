cmd="xcodeGen/run_with_mint.sh sourcery --config"

for config in sourcery/*.yaml
do
    $cmd "$config"
done
