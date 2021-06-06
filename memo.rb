# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'pg'

class Memo
  class << self
    def create_db
      db = PG.connect(dbname: 'postgres')
      db.exec 'CREATE TABLE IF NOT EXISTS Memos(Id serial PRIMARY KEY, Title text NOT NULL, Article text NOT NULL, Edit_Id VARCHAR(36))'
    end

    def load_memo(edit_id = nil)
      db = PG.connect(dbname: 'postgres')
      if edit_id
        db.prepare('load', 'SELECT * FROM Memos WHERE edit_id = $1')
        db.exec_prepared('load', [edit_id])
      else
        db.exec('SELECT * FROM Memos')
      end
    end

    def add_memo(title, article, edit_id)
      db = PG.connect(dbname: 'postgres')
      db.prepare('add', 'INSERT INTO Memos (title, article, edit_id) VALUES ($1, $2, $3)')
      db.exec_prepared('add', [title, article, edit_id])
    end

    def delete_memo(edit_id)
      db = PG.connect(dbname: 'postgres')
      db.prepare('delete', 'DELETE FROM Memos WHERE edit_id = $1')
      db.exec_prepared('delete', [edit_id])
    end

    def updated_memo(title, article, edit_id)
      db = PG.connect(dbname: 'postgres')
      db.prepare('update', 'UPDATE Memos SET title = $1, article = $2 WHERE edit_id = $3')
      db.exec_prepared('update', [title, article, edit_id])
    end
  end
end

Memo.create_db

get '/' do
  Memo.create_db
  @memos = Memo.load_memo.sort_by { |memo| memo['id'] }
  erb :home
end

post '/' do
  edit_id = SecureRandom.uuid
  Memo.add_memo(params[:title], params[:article], edit_id)
  redirect to('/')
end

get '/new' do
  erb :new
end

get '/memos/:id' do
  memo = Memo.load_memo(params[:id])
  @edit_id = params[:id]
  @title = memo[0]['title']
  @article = memo[0]['article']
  erb :detail
end

delete '/memos/:id' do
  Memo.delete_memo(params[:id])
  redirect to('/')
end

get '/memos/:id/edit' do
  memo = Memo.load_memo(params[:id])
  @edit_id = params[:id]
  @title = memo[0]['title']
  @article = memo[0]['article']
  erb :edit
end

patch '/memos/:id' do
  Memo.updated_memo(params[:title], params[:article], params[:id])
  redirect to('/')
end

not_found do
  status 404
end
