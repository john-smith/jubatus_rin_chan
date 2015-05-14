#!/bin/bash

# jubatus起動
echo "jubatus"
jubaclassifier -f rin_chan.json &

echo "split file"
rm -rf split_train
mkdir split_train
split -l 50 -d -a 03 data/train_data.tsv split_train/train.

rm -rf test
mkdir test
rm -rf train
mkdir train

train=train/predict

echo "training and predict"
for i in `seq 0 119`; do
	train_file=`printf "split_train/train.%03d" $i`
	test_result=`printf "test/result%03d.csv" $i`
	train_result=`printf "train/result%03d.csv" $i`

	cat $train_file >> $train
	
	ruby rin_chan.rb train $train_file
	ruby rin_chan.rb predict data/test_data.tsv > $test_result
	ruby rin_chan.rb predict $train > $train_result
done

ruby rin_chan.rb score data/test_data.tsv > score.csv

# バックグラウンドで動かしてたjubatusを殺す
echo "kill jubatus"
killall jubaclassifier

echo "end"
