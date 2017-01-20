module ArticleSeeds

using App, SearchLight, Faker

function create_random(no_of_articles::Int = 10)
  for i in 1:no_of_articles
    article = Articles.random()

    SearchLight.save!!(article)
  end
end

end
