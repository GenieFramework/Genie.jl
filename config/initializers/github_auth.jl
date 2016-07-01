using GitHub
const GITHUB_AUTH = try 
                      GitHub.authenticate(GITHUB_AUTH_KEY)
                    catch ex 
                      Genie.log("Can't auth to GitHub", :err)
                      Genie.log(ex, err)

                      nothing
                    end