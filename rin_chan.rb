# -*- coding: utf-8 -*-
require 'jubatus/classifier/client'
require 'mecab'

# 凛ちゃん分類のためのJubatusです
class Rin_chan
  def initialize(host, port, name)
    # juatusとmecabの初期化は定型文だと思って大丈夫
    @client = Jubatus::Classifier::Client::Classifier.new(host, port, name)
    @mt = MeCab::Tagger.new
  end

  # 正解となる凛ちゃんとレス一つのセットが1行になったデータを読み込んでる
  # 学習用
  def train_file(file)
    File.open(file).each do |line|
      label, text = line.chomp.split("\t")
      train(label, text)
    end
  end

  # 学習させる
  def train(label, data)
    # 形態素解析して単語ごとの出現回数をHashにしてある
    terms = ma(data)
    # jubatusで学習させてる
    @client.train([[label, Jubatus::Common::Datum.new(terms)]])
  end

  # 正解となる凛ちゃんとレス一つのセットが1行になったデータを読み込んでる
  # 学習用とほぼ一緒だけど面倒なのでdryな書き方じゃなくなった
  def predict_file(file)
    File.open(file).inject([]) do |results, line|
      label, text = line.chomp.split("\t")
      results << [predict(text), label]
      results
    end
  end

  # レスからどの凛ちゃんの話題かを予測してる
  def predict(data)
    terms = ma(data)
    # 予測結果の取得
    predict = @client.classify([Jubatus::Common::Datum.new(terms)])[0].max_by {|i| i.score}.label
  end

  # 正解となる凛ちゃんとレス一つのセットが1行になったデータを読み込んでる
  # 学習用とほぼ一緒だけど面倒なのでdryな書き方じゃなくなった
  def score_file(file)
    File.open(file).inject([]) do |results, line|
      label, text = line.chomp.split("\t")
      results << score(text)
      results
    end
  end

  # レスごとにどの凛ちゃんっぽいかを各凛ちゃんごとにスコアで出す
  def score(data)
    terms = ma(data)
    @client.classify([Jubatus::Common::Datum.new(terms)])[0].inject([]) do |result, line|
      result << line.score
      result
    end
  end

  # 形態素解析してる
  def ma(text)
    @mt.parse(text).split("\n").inject({}) do |result, item|
      # 全部終わった合図として最期にEOSが追加されてるのでそこで終了
      # jubatusではkeyが「$」はだめっぽいのでそれも除外してる
      if item != "EOS" && !item.include?('$')
        term = item.split("\t")[0]
        result[term] = 0 if result[term].nil?
        result[term] += 1
      end
      result
    end
  end
end

rin_chan = Rin_chan.new("127.0.0.1", 9199, "rin_chan")
if ARGV[0] == 'train'
  rin_chan.train_file(ARGV[1])
elsif ARGV[0] == 'predict'
  rin_chan.predict_file(ARGV[1]).each {|i| puts "#{i[0]},#{i[1]}"}
elsif ARGV[0] == 'score'
  rin_chan.score_file(ARGV[1]).each {|i| puts i.join(",")}
else
  puts "Error mode:#{ARGV[0]} is missing."
end
