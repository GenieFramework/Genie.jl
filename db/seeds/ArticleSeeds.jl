module ArticleSeeds
using App, SearchLight
using Faker

function create_random(no_of_articles::Int = 10)
  for i in 1:no_of_articles
    article = Article()
    article.title = Faker.sentence()

    while length(article.title) < 20
      article.title *= ". " * Faker.sentence()
    end

    article.summary = join(Faker.sentences(), "\n")
    article.content = join(Faker.paragraphs(), "\n")

    SearchLight.save!!(article)
  end
end

end