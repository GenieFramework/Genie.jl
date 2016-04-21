type ReposController <: Jinnie.JinnieController
end

index(_::ReposController, req, res, params) = "Repo index" 