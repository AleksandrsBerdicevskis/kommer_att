corpora = ["familjeliv","svt","gp","da","flashback","twitter","bloggmix"]

require_relative "corpus_tools"
#also shrinking and simplifying predictors
status_index = nil
relpos_index = nil 
between_index = nil
att_before_index = nil
att_after_index = nil
discarded = 0
distance_index = nil
id_index = nil
corpus_index = nil
o2 = File.open("Summary\\kommer_att_predictors_all.tsv","w:utf-8")
flag = true
global_id = 0
corpora.each do |maincorpus|
    STDERR.puts maincorpus
    f = File.open("Summary\\kommer_att_predictors_#{maincorpus}.tsv","r:utf-8")
    
        
        f.each_line.with_index do |line, index|
        line1 = line.strip
        if index % 1000000 == 0
            STDERR.puts index
        end
    
        if index == 0 
            if flag
                headers = line1.split("\t")
                status_index = headers.index("status")
                relpos_index = headers.index("subject_relpos")
                between_index = headers.index("att_between")
                att_before_index = headers.index("att_before")
                att_after_index = headers.index("att_after")
                distance_index = headers.index("distance_to_att_words")
                corpus_index = headers.index("corpus")
                o2.puts ["global_id", headers[0..1], headers[3..6], headers[10..11], headers[15..17], headers[21], "subject", headers[30..34], "maincorpus"].join("\t")
                flag = false
            end
        else
            line2 = line1.split("\t")
            #if line2[status_index] != "noise" and line2[relpos_index] != "after_verb" and line2[relpos_index] != "after_att" and line2[between_index].to_i < 2 and line2[distance_index].to_i < 6
            global_id += 1
            if line2[att_before_index].to_i > 0
                line2[att_before_index] = "yes"
            else
                line2[att_before_index] = "no"
            end

            if line2[att_after_index].to_i > 0
                line2[att_after_index] = "yes"
            else
                line2[att_after_index] = "no"
            end
            if line2[relpos_index] != "before" and line2[relpos_index] != "after" 
                line2[relpos_index] = "no"
            else
                line2[relpos_index] = "yes"
            end

                #o2.puts [global_id, line2[0..1], line2[3..6], line2[10..11], line2[15..17], line2[21], line2[29..34], line2[36..37], line2[39..-1], get_maincorpus(line2[corpus_index])].join("\t")
                o2.puts [global_id, line2[0..1], line2[3..6], line2[10..11], line2[15..17], line2[21], line2[29..34], get_maincorpus(line2[corpus_index])].join("\t")
            #else
            #    STDOUT.puts line1
            #    discarded += 1
            #end
            
        end
    end
end
STDERR.puts discarded
