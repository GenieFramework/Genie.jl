using Router

route("/") do
  Flax.include_template("$(Genie.LAYOUTS_PATH)/app.flax.html", partial = false)
end
