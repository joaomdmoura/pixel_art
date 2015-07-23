use Mix.Config

# In this file, we keep production configuration that
# you likely want to automate and keep it away from
# your version control system.
config :pixel_art, PixelArt.Endpoint,
  secret_key_base: "L+txmk1n040kF4OclJw7nb1FsaP+qgtk8jULTPoTc5s2tQaPnYc+J1cir8FzEDrG"

# Configure your database
config :pixel_art, PixelArt.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "pixel_art_prod",
  size: 20 # The amount of database connections in the pool
