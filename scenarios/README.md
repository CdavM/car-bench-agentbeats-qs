# Amber instructions

## Provide env values
```bash
cp sample.env .env
```

And fill out.


## Compile

```bash
./amber compile amber-scenario.json5 --docker-compose car-bench.yml
```

## Run

```bash
export $(grep -v '^#' .env | xargs) && docker compose -f car-bench.yml up
```
