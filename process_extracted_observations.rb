require_relative 'corpus_tools'
require_relative 'net_tools.rb'

variable = "kommer_att"
maincorpora = ARGV[0].split(",")

#remove 
def cleant(parameter)
    
    if !parameter.nil?
        parameter.gsub!("\t","")
    end
    return parameter
end

maincorpora.each do |maincorpus|
    STDERR.puts maincorpus
    input_dir = "Jsons_#{maincorpus}"
    output_dir = "Summary"
    predictor_file = File.open("#{output_dir}\\#{variable}_predictors_#{maincorpus}.tsv","w:utf-8")
    
 
    header = "unique_id\tcorpus\tmatch_position\tyear\tauthor\tplaintext\tstatus\tkommer_position\tatt_position\tverb_position\tverb_lemma\tdistance_to_att_words\tdistance_to_att_symbols\tdistance_to_verb_words\tdistance_to_verb_symbols\tvoice\tinf_length\tatt_before\tdistance_att_before_words\tdistance_att_before_symbols\tatt_between\tatt_after\tdistance_att_after_words\tdistance_att_after_symbols\tsubject_id\tsubject_form\tsubject_lemma\tsubject_type\tsubject_pos\tsubject_relpos\tgenre\tmonth\tday\ttime\ttext_id\tthread_id\tposlist\tsection\tshortsection\tuserid"
        
    predictor_file.puts header
    
    date_sep = {"familjeliv" => " ", "svt" => "T", "da" => " ", "flashback" => " ", "twitter" => " "}
    
    
    filelist = Dir.children(input_dir) 
    thread_id = nil
    section = nil
    shortsection = nil
    message_id = nil
    userid = nil
    unique_id = 0 
    discarded = 0
    
    
    filelist.each do |filename2|
        if filename2.split(".")[1] == "json"
            STDERR.puts filename2
            STDERR.puts "Processing Korp's output..."
            
            
            file = File.read("#{input_dir}\\#{filename2}")
            data_hash = JSON.parse(file)
            if data_hash["ERROR"].nil?
                  
                hits = data_hash["kwic"]
                 
                hits.each do |hit|
                    if hit["tokens"][0]["ref"].to_i == 1 
                        unique_id += 1
                        output_array = []
                        output_array << unique_id
                        corpus_from_json = hit["corpus"]
                        maincorpus = get_maincorpus(corpus_from_json)
                        #maincorpus = corpus_from_json.split("-")[0].downcase
                        genre = get_genre(maincorpus)
                        output_array << corpus_from_json
                        match_position = hit["match"]["position"]
                        
                        output_array << match_position
                        match_start = hit["match"]["start"].to_i
                        match_end = hit["match"]["end"].to_i
                        if maincorpus != "gp" and maincorpus != "bloggmix" and maincorpus != "twitter" and maincorpus != "press2" and maincorpus != "dn"
                            date = hit["structs"]["text_date"].split(date_sep[maincorpus])[0]
                            time = hit["structs"]["text_date"].split(date_sep[maincorpus])[1]
                        elsif maincorpus == "twitter"
                            date = hit["structs"]["text_datetime"].split(date_sep[maincorpus])[0]
                            time = hit["structs"]["text_datetime"].split(date_sep[maincorpus])[1]
                        elsif maincorpus == "press2" 
                            date = hit["structs"]["text_year"]
                            time = nil
                        else
                            date = hit["structs"]["text_date"]
                            time = nil
                        end
                        year = date.split("-")[0]
                        month = date.split("-")[1]
                        day = date.split("-")[2]
                       
                        if maincorpus == "familjeliv" or maincorpus == "flashback"
                            username = hit["structs"]["text_username"]
                            thread_id = hit["structs"]["thread_id"]
                        elsif maincorpus == "svt"
                            username = hit["structs"]["text_authors"]
                            section = hit["structs"]["text_section"]
                        elsif maincorpus == "gp"
                            username = hit["structs"]["text_author"]
                            section = hit["structs"]["text_section"]
                            shortsection = hit["structs"]["text_sectionshort"]
                        elsif maincorpus == "da"
                            username = hit["structs"]["text_author"]
                        elsif maincorpus == "twitter"
                            username = hit["structs"]["user_username"]
                        elsif maincorpus == "bloggmix"
                            username = hit["structs"]["blog_title"]
                        end
                        
                        if maincorpus == "gp" 
                            message_id = hit["structs"]["text_title"]
                        elsif maincorpus == "bloggmix"
                            message_id = "#{hit["structs"]["text_title"]}___#{hit["structs"]["text_url"]}"
                        else
                            message_id = hit["structs"]["text_id"]
                        end
                        if maincorpus == "flashback"
                            userid = hit["structs"]["text_userid"]
                        end
                        output_array << year
                        output_array << cleant(username)
                        
                        #tokens_rep = []
                        tokens = hit["tokens"]
                        
                        kommer_id = 0
                        vb_id = 0
                        kommer_head = 0
                        vb_head = 0
                        vb_form = ""
                        vb_lemma = ""
                        vb_voice = "unknown"
                        att_before = 0
                        att_before_id = 0
                        att_after = 0
                        att_after_id = 0
                        
                        
                        att_ids = []
                        att_heads = []
                        att_id = 0
                        subject_id = 0
                        subject_word = ""
                        subject_lemma = ""
                        subject_type = ""
                        subject_pos = ""
                        subject_relpos = ""
                    
                        
                        plain_rep = []
                        pos_rep = []
                    
                    
                        inf_complexity = 1
                        inf_head = 0
                        vg_att_head = 0
                        vg_att_flag = false
                        distance_words = 0
                        distance_symbols = 0
                        distance_words_verb = 0
                        distance_symbols_verb = 0
                        distance_att_before_words = ""
                        distance_att_before_symbols = ""
                        distance_att_after_words = ""
                        distance_att_after_symbols = ""
                        #distance_att_after_words_from_last_verb = ""
                        #distance_att_after_symbols_from_last_verb = ""
                        count_distance = true
                        
                    
                        tokens.each do |token|
                                            
                            id = token["ref"].to_i
                            head = token["dephead"].to_i
                            
                            plain_rep << token["word"]
                            pos_rep << token["pos"]
                            if !token["lemma"].nil? 
                                lemma = token["lemma"].split("|")[1].to_s
                            else
                                lemma = token
                            end
                            if lemma == "" or lemma == "|"
                                lemma = token["word"]
                            end
                           
                            if (token["deprel"] == "SS" or token["deprel"] == "FS") and head == match_start + 1
                                subject_id = id
                                subject_word = token["word"]
                                subject_lemma = lemma
                                if token["deprel"] == "SS"
                                    subject_type = "other"
                                else
                                    subject_type = "dummy"
                                end
                                
                                subject_pos = token["pos"]
                                if subject_id < match_start + 1
                                    subject_relpos = "before"
                                elsif subject_id > match_start + 1
                                    subject_relpos = "after"
                                end
                                
                            end
                    
                            if id - 1 < match_start 
                            
                                if token["word"] == "att"
                                    att_before += 1
                                    att_before_id = id
                                    distance_att_before_words = 1
                                    distance_att_before_symbols = 1
                                elsif att_before > 0
                                    if !["MAD","MID","PAD"].include?(token["pos"])
                                        distance_att_before_words += 1
                                        distance_att_before_symbols += token["word"].length
                                    end
                                end
                    
                            elsif id - 1 == match_start
                            
                                kommer_id = id
                                kommer_head = head
                                distance_words = 1
                                distance_symbols = 1
                                distance_words_verb = 1
                                distance_symbols_verb = 1
                            elsif id > match_start+1 and id < match_end
                                
                                if token["word"] == "att" 
                                    count_distance = false #it MIGHT be a different att, otherwise we do not need the extra check below. But that will change once I add syntax
                                    att_ids << id
                                    att_heads << head
                                end
                                if count_distance
                                    if !["MAD","MID","PAD"].include?(token["pos"])
                                        distance_words += 1
                                        distance_symbols += token["word"].length
                                    end
                                end
                                
                                if !["MAD","MID","PAD"].include?(token["pos"])
                                    distance_words_verb += 1
                                    distance_symbols_verb += token["word"].length
                                end
                                
                                        
    			    
                            elsif id  == match_end 
                                
                                vb_id = id
                    
                                vb_head = head
                                inf_head = vb_id
                                vb_form = token["word"].downcase
                                vb_lemma = lemma
                                if token["msd"].include?("AKT")
                                    vb_voice = "active"
                                elsif token["msd"].include?("SFO")
                                    vb_voice = "s-form"
                                end
                                distance_att_after_words = 1
                                distance_att_after_symbols = 1
                    
                            elsif id > match_end 
                                
                                if (token["pos"] == "VB" and token["msd"].include?("INF") and head == inf_head)
                                    inf_complexity += 1
                                    inf_head = id
                                    vg_att_flag = false
                                elsif token["word"] == "att" and head == inf_head #add deprel?
                                
                                    vg_att_flag = true
                                    vg_att_head = id
                                elsif vg_att_flag and token["pos"] == "VB" and token["msd"].include?("INF") and head == vg_att_head
                                
                                    inf_complexity += 1
                                    inf_head = id
                                    vg_att_flag = false
                                end
                                
                                if token["word"] == "att"
                                    if att_after_id == 0
                                        att_after_id = id
                                    end
                                    att_after += 1
                                elsif att_after == 0
                                    if !["MAD","MID","PAD"].include?(token["pos"])
                                        distance_att_after_words += 1
                                        distance_att_after_symbols += token["word"].length
                                    end
                                end
                            end
                    
                            
                         
                        end
                        output_array << cleant(plain_rep.join(" "))
                        
                        if vb_head == kommer_id
                            status = "omission"
                        else
                            flag = false
                            for i in 0..(att_ids.length - 1)
                                if vb_head == att_ids[i] and att_heads[i] == kommer_id
                                    flag = true
                                    att_id = att_ids[i]
                                    break
                                    
                                end
                            end 
                            if flag
                                status = "att"
                            else
                                status = "noise"
                            end
                        end
                        output_array << status
                        output_array << kommer_id
                        output_array << att_id
                        output_array << vb_id
                        output_array << vb_lemma
                    
                        if att_after == 0
                            distance_att_after_words = ""
                            distance_att_after_symbols = ""
                        end
                    
                        if maincorpus == "bloggmix" and !hit["structs"]["blog_age"].nil? and hit["structs"]["blog_age"] != ""and !hit["structs"]["blog_age"].include?("-")
                            if !(hit["structs"]["blog_age"].to_i > 80 or hit["structs"]["blog_age"].to_i < 12)
                                birthyear = year.to_i - hit["structs"]["blog_age"].to_i
                                birthyears << birthyear
                            end
                        end
                        
                        
                        output_array << distance_words
                        output_array << distance_symbols
                        output_array << distance_words_verb
                        output_array << distance_symbols_verb
                    
                        output_array << vb_voice
                        output_array << inf_complexity
                        output_array << att_before
                        output_array << distance_att_before_words
                        output_array << distance_att_before_symbols
                        output_array << att_ids.length
                        output_array << att_after
                        output_array << distance_att_after_words
                        output_array << distance_att_after_symbols
                        
                        if subject_id > vb_id
                            subject_relpos = "after_verb"
                        elsif subject_id > att_id and att_id != 0
                            subject_relpos = "after_att"
                        end
                    
                        output_array << subject_id 
                        output_array << subject_word
                        
                        output_array << subject_lemma
                        output_array << subject_type
                        output_array << subject_pos
                        output_array << subject_relpos
                        output_array << genre
                        output_array << month
                        output_array << day
                        output_array << time
                        output_array << cleant(message_id)
                        output_array << cleant(thread_id)
                        output_array << pos_rep.join(" ")
                        output_array << cleant(section)
                        output_array << cleant(shortsection)
                        output_array << cleant(userid)
                    
                        if status != "noise" and att_ids.length < 2 and subject_relpos != "after_verb" and subject_relpos != "after_att" and distance_words < 6
                            predictor_file.puts output_array.join("\t")
                        else
                            discarded += 1
                            #STDOUT.puts output_array.join("\t") #uncomment to output the discarded observations
                        end
                    end
                end
                    
            else
                STDERR.puts "Error! #{filename2}\t#{searchyear}\t#{searchmonth}"
                
            end
            
        end #corpora
    end
    STDERR.puts "Discarded:#{discarded}"
    
end