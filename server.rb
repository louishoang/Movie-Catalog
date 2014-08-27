require 'sinatra'
require 'sinatra/reloader'
require 'pry'
require 'pg'

def db_connection
  begin
    connection = PG.connect(dbname: 'movies')

    yield(connection)

  ensure
    connection.close
  end
end

def get_data(query)
  db_connection do |conn|
    conn.exec(query)
  end
end

def get_data_with_query(query, id)
  db_connection do |conn|
   conn.exec(query, [id])
  end
end

def sort_by_params(query, sort)

end

get '/' do
  redirect '/movies'
end

get '/actors' do
  query = 'SELECT actors.id, actors.name
   FROM actors ORDER BY actors.name'
  @actors = get_data(query)
  erb :'actors/index'
end

get '/actors/:id' do
  id = params[:id]

  query = 'SELECT movies.id AS movie_id, actors.id AS actor_id,
   actors.name, cast_members.character,movies.title
    FROM movies JOIN cast_members
    ON movies.id = cast_members.movie_id
    JOIN actors ON cast_members.actor_id = actors.id
    WHERE actors.id = $1'
  @person = get_data_with_query(query, id)
  erb :'actors/show'
end

get '/movies' do
  query = 'SELECT movies.id, movies.title, movies.year,
   movies.rating, genres.name
   AS genre, studios.name AS studio
   FROM movies JOIN genres
   ON movies.genre_id = genres.id
   LEFT OUTER JOIN studios ON movies.studio_id = studios.id '

  sort_by_params(query, params[:order])

  case params[:order]
  when 'rating'
    query += ' ORDER BY movies.rating LIMIT 20 '
  when 'year'
    query += ' ORDER BY movies.year DESC LIMIT 20 '
  when
    query += ' ORDER BY movies.title ASC LIMIT 20 '
  end

  page = params[:page].to_i
  page ||= 1
  offset = ((page * 20) - 20).to_s
  if offset.to_i > 0
    query += ' OFFSET ' + offset
  else
    query
  end
  @movies = get_data(query)

  erb :'movies/index'
end

get '/movies/:id' do
  id = params[:id]
  query = 'SELECT actors.id as actor_id, movies.title,
   genres.name AS genre, studios.name
   AS studio, actors.name AS actors, cast_members.character
   AS roles FROM movies JOIN genres
   ON movies.genre_id = genres.id
   LEFT OUTER JOIN studios
   ON movies.studio_id = studios.id
   LEFT OUTER JOIN cast_members ON movies.id = cast_members.movie_id
   LEFT OUTER JOIN actors ON cast_members.actor_id = actors.id
   WHERE movies.id = $1'
  @indi_movie = get_data_with_query(query, id)
  erb :'movies/show'
end

post '/movies' do
  redirect '/movies'
end
