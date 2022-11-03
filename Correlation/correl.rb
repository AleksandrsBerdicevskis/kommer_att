#require "rinruby"

#use merge.rb to create the input file from the samples (extract them from samples.zip)
input_file = File.open("kommer_att_predictors_balanced.tsv","r:utf-8")
parameters = ["voice", "inf_length", "att_before", "att_after",  "distance_to_att_words", "subject","attraction","time"] 
maincorpora = ["all","bloggmix","da","familjeliv","flashback","gp","svt","twitter"]

value_hash = Hash.new{|hash,key| hash[key] = Hash.new{|hash1,key1| hash1[key1] = Array.new}}
status_hash = Hash.new{|hash,key| hash[key] = Hash.new{|hash1,key1| hash1[key1] = Array.new}}



def pearson(x,y)
  n=x.length

  sumx=x.inject(0) {|r,i| r + i}
  sumy=y.inject(0) {|r,i| r + i}

  sumxSq=x.inject(0) {|r,i| r + i**2}
  sumySq=y.inject(0) {|r,i| r + i**2}

  prods=[]; x.each_with_index{|this_x,i| prods << this_x*y[i]}
  pSum=prods.inject(0){|r,i| r + i}

  # Calculate Pearson score
  num=pSum-(sumx*sumy/n)
  den=((sumxSq-(sumx**2)/n)*(sumySq-(sumy**2)/n))**0.5
  if den==0
    return 0
  end
  r=num/den
  return r
end

par_index = {}
status_index = 0
year_index = 0
month_index = 0

maincorpus_index = 0
test_index = 0
input_file.each_line.with_index do |line, index|
    if index % 100000 == 0 
        STDERR.puts index
    end
    line1 = line.gsub("\r","")
    line1 = line1.gsub("\n","")
    if index == 0
        headers = line1.split("\t")
        parameters.each do |parameter|
            par_index[parameter] = headers.index(parameter)
        end
        status_index = headers.index("outcome")
        test_index = headers.index("test")
        year_index = headers.index("year")
        month_index = headers.index("month")
        maincorpus_index = headers.index("maincorpus")
    else
        line2 = line1.split("\t")
        maincorpus = line2[maincorpus_index]
        
        if line2[test_index] == "0"

            parameters.each do |parameter|

                if parameter == "time"
                    year = line2[year_index].to_i
                    month = line2[month_index].to_i
                    value = year*12 + month
                else
                    value = line2[par_index[parameter]].to_f
                end
                #STDERR.puts value
                
                status = line2[status_index]
                if status == "omission"
                    status = 1.0
                elsif status == "att"
                    status = 0.0
                else
                    status = status.to_f
                end
                value_hash[maincorpus][parameter] << value
                status_hash[maincorpus][parameter] << status

            end
            
        end
    end
end

o = File.open("correl.tsv","w:utf-8")
o.puts "corpus\t#{parameters.join("\t")}"


maincorpora.each do |maincorpus|
    
    output_line = maincorpus.clone
    parameters.each do |parameter|
        x = value_hash[maincorpus][parameter]
        y = status_hash[maincorpus][parameter]
        r = pearson(x,y)
        output_line << "\t#{r}"
    end
    o.puts output_line
end

