# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'json'

def read_json_file
  files = Dir.glob('memos/*').sort_by { |file| File.mtime(file) }
  files.map { |memo| JSON.parse(File.read(memo)) }
end

helpers do
  def escape(text)
    Rack::Utils.escape_html(text)
  end
end

before '/' do
  @title = params[:title]
  @article = params[:article]
  @id = params[:id]
end

get '/' do
  @memos = read_json_file
  erb :home
end

post '/' do
  memo = { 'title' => escape(params[:title]).to_s, 'article' => escape(params[:article]).to_s, 'id' => SecureRandom.uuid }
  File.open("memos/#{memo['title']}.json", 'w') do |file|
    JSON.dump(memo, file)
  end
  redirect to('')
end

get '/new' do
  erb :new
end

get '/memos/:id' do
  memos = read_json_file
  memos.each do |memo|
    next unless memo['id'] == params[:id]

    @id = memo['id']
    @article = memo['article']
    @title = memo['title']
  end
  erb :detail
end

delete '/memos/:id/edit' do
  memos = read_json_file
  memos.each do |memo|
    next unless memo['id'] == params[:id]

    @id = memo['id']
    @title = memo['title']
    File.delete("memos/#{@title}.json")
  end
  redirect to('')
end

get '/memos/:id/edit' do
  memos = read_json_file
  memos.each do |memo|
    next unless memo['id'] == params[:id]

    @id = memo['id']
    @article = memo['article']
    @title = memo['title']
  end
  erb :edit
end

patch '/memos/:id/edit' do
  memos = read_json_file
  memos.each do |memo|
    next unless memo['id'] == params[:id]

    @id = memo['id']
    @title = memo['title']
    updated_memo = { 'title' => escape(params[:title]).to_s, 'article' => escape(params[:article]).to_s, 'id' => memo['id'] }
    File.open("memos/#{@title}.json", 'w') do |file|
      JSON.dump(updated_memo, file)
    end
  end
  redirect to('')
end

not_found do
  status 404
end
