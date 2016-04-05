type RepoController <: JinnieController
end

index(_::RepoController, req) = "Repo index" 