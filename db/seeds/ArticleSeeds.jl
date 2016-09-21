module ArticleSeeds
using App, Model
using Faker

function create_random(no_of_articles::Int = 10)
  for i in 1:no_of_articles
    article = Article()
    article.title = Faker.text()
    article.summary = join(Faker.sentences(), "\n")
    article.content = join(Faker.paragraphs(), "\n")

    Model.save!!(article)
  end
end

end