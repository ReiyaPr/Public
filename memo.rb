# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'pg'

class Memo
  class << self
    def create_db(db)
      db.exec 'CREATE TABLE IF NOT EXISTS Memos(Id serial PRIMARY KEY, Title text NOT NULL, Article text NOT NULL)'
    end

    def load_all_memos(db)
      db.exec('SELECT * FROM Memos')
    end

    def prepared_statesments(db)
      db.prepare('load', 'SELECT * FROM Memos WHERE id = $1')
      db.prepare('add', 'INSERT INTO Memos (title, article) VALUES ($1, $2)')
      db.prepare('delete', 'DELETE FROM Memos WHERE id = $1')
      db.prepare('update', 'UPDATE Memos SET title = $1, article = $2 WHERE id = $3')
    end

    def load_memo(db, id)
      db.exec_prepared('load', [id])
    end

    def add_memo(db, title, article)
      db.exec_prepared('add', [title, article])
    end

    def delete_memo(db, id)
      db.exec_prepared('delete', [id])
    end

    def updated_memo(db, title, article, id)
      db.exec_prepared('update', [title, article, id])
    end
  end
end

db = PG.connect(dbname: 'postgres')
Memo.create_db(db)
Memo.prepared_statesments(db)

get '/' do
  @memos = Memo.load_all_memos(db).sort_by { |memo| memo['id'] }
  erb :home
end

post '/' do
  Memo.add_memo(db, params[:title], params[:article])
  redirect to('/')
end

get '/new' do
  erb :new
end

get '/memos/:id' do
  @memo = Memo.load_memo(db, params[:id])
  erb :detail
end

delete '/memos/:id' do
  Memo.delete_memo(db, params[:id])
  redirect to('/')
end

get '/memos/:id/edit' do
  @memo = Memo.load_memo(db, params[:id])
  erb :edit
end

patch '/memos/:id' do
  Memo.updated_memo(db, params[:title], params[:article], params[:id])
  redirect to('/')
end

not_found do
  status 404
end
