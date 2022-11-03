#extract all non-consecutive samples from samples.zip, put them in the same folder as this script and run it.

filelist = Dir.children(".")
STDERR.puts filelist
o = File.open("kommer_att_predictors_balanced.tsv","w:utf-8")
o.puts "maincorpus	global_id	year	month	outcome	test	voice	subject	att_before	att_after	genre	inf_length	distance_to_att_words	attraction"
filelist.each do |filename|
    STDERR.puts filename
    if filename[-4..-1] == ".csv"
        f = File.open(filename,"r:utf-8")
        maincorpus = filename.split("_")[0]
        r = f.readlines
        r[1..-1].each do |line|
            o.puts "#{maincorpus}\t#{line.strip}"
        end
    end
end