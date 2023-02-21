PATH = ""

def get_years(corpus,maincorpus,yearlycorpus=false)
    if yearlycorpus and ["svt","gp","bloggmix","press","webbnyheter"].include?(maincorpus)
        years = [corpus[-4..-1].to_i]
    else
    
        if maincorpus == "flashback"
            start = 2001 
            finish = 2021
        elsif maincorpus == "familjeliv"
            start = 2003
            finish = 2021
        elsif maincorpus == "svt"
            start = 2004
            finish = 2021
            #corpus  = corpus.upcase
        elsif maincorpus == "gp"
            start = 2001
            finish = 2013
        elsif maincorpus == "twitter"
            if corpus == maincorpus
                start = 2006
                finish = 2019
            else
                start = corpus.split("-")[1].to_i
                finish = start
            end
        elsif maincorpus == "rd"
            start = 2003
            finish = 2019
        elsif maincorpus == "da"
            start = 2007
            finish = 2021
        elsif maincorpus == "bloggmix"
            start = corpus[8..-1].to_i
            finish = start
        elsif maincorpus == "press"
            years = [1965,1995,1996,1997,1998]
        elsif maincorpus == "press2"
            years = [1976]
        elsif maincorpus == "dn"
            years = [1987]
        
        end
    
        if maincorpus != "press" and maincorpus != "press2" and maincorpus != "dn"
            years = (start..finish).to_a
        end
    end
    return years
end

def get_maincorpus_from_label(label)
    maincorpus = label.split("-")[0].downcase 
    
    return maincorpus
end



def get_maincorpus(corpus)
    if corpus[0..1].downcase != "gp" and corpus[0..7].downcase != "bloggmix" and corpus[0..4].downcase != "press" and corpus[0..1].downcase != "dn" and corpus[0..3].downcase != "webb"
        maincorpus = corpus.split("-")[0].downcase 
    else
        if corpus[0..1].downcase == "gp" 
            maincorpus = "gp"
        elsif corpus[0..7].downcase == "bloggmix"
            maincorpus = "bloggmix"
        elsif corpus[0..4].downcase == "press"
            if corpus[5..6] == "76"
                maincorpus = "press2"
            else
                maincorpus = "press"
            end
        elsif corpus[0..1].downcase == "dn"
            maincorpus = "dn"
        elsif corpus[0..3].downcase == "webb"
            maincorpus = "webbnyheter"
        end
    end
    return maincorpus
end

def get_genre(maincorpus)#, getmain=true)
    genre_hash = {"familjeliv" => "socmedia", "flashback" => "socmedia", "twitter" => "socmedia", "rd" => "official", "svt" => "news", "gp" => "news", "da" => "news", "podiet" => "news", "bloggmix" => "socmedia","press" => "news", "press2" => "news","dn"=>"news","webbnyheter"=>"news"}
    genre = genre_hash[maincorpus]
    return genre
end

def get_structs(maincorpus)
    #maincorpus = get_maincorpus(corpus)
    if maincorpus == "familjeliv"
        structs = "text_date,text_username,text_id,thread_id"
    elsif maincorpus == "flashback"
        structs = "text_date,text_username,text_id,thread_id,text_userid"
    elsif maincorpus == "svt"
        structs = "text_date,text_authors,text_id,text_section"
    elsif maincorpus == "gp"
        structs = "text_date,text_author,text_section,text_sectionshort,text_title"
    elsif maincorpus == "da"
        structs = "text_date,text_author,text_id"
    elsif maincorpus == "twitter"
        structs = "text_datetime,user_username,text_id"
    elsif maincorpus == "bloggmix"
        structs = "text_date,text_title,text_url,blog_title,blog_age,blog_city"
    elsif maincorpus == "press"
        structs = "text_date"
    elsif maincorpus == "press2"
        structs = "text_year"
    elsif maincorpus == "dn"
        structs = "text_date"
    elsif maincorpus == "webbnyheter"
        structs = "text_date,text_url,text_newspaper"
    end
end

def read_corpus_label(corpus_and_label)
    maincorpus = corpus_and_label.split("-")[0]
    label = corpus_and_label.split("-")[1..-1].join("-")


    corpus = ""
    labelfile = File.open("#{PATH}subforum_labels.tsv", "r:utf-8")
    labelfound = false
    labelfile.each_line do |line|
        line1 = line.strip.split("\t")
        if line1[0] == corpus_and_label
            
            line1[1].split(",").each do |subcorp|
                if line1[2] == "merge"
                    corpus << maincorpus#.upcase
                end
                corpus << subcorp#.upcase
                corpus << ","
            end
            corpus = corpus[0..-2]
            
            labelfound = true
            break
        end
    end
    if corpus != ""
       corpora = corpus.split(",")
    else
       corpora = [corpus_and_label]
    end
    
    #STDERR.puts corpora
    return corpora
end

def read_in_variable(varname, useradd, nvariants, source="korp_queries.rb")
    #STDERR.puts varname
    f_input = File.open("#{PATH}#{source}","r:utf-8")
    flag = false
    found = false
    variant1 = ""
    variant2 = ""
    f_input.each_line do |line|
        line1 = line.strip
        if line1 == "__END__"
            break
        elsif line1 == "#label = #{varname}"
            flag = true
        elsif flag and line1.split(" = ")[0] == "variant1"
            variant1 = line1.split(" = ")[1..-1].join(" = ") #.gsub("\"","")
            if nvariants == 1
                found = true
                break
            end
        elsif flag and line1.split(" = ")[0] == "variant2"
            variant2 = line1.split(" = ")[1..-1].join(" = ") #.gsub("\"","")
            found = true
            break
        end
    end
    if !found
        abort "Cassandra says: No variable matches this label, check korp_queries.rb"
    end
    bracket_index = variant1.index("]")
    variant1 = "#{variant1[0..bracket_index-1]}#{useradd}#{variant1[bracket_index..-1]}"
    #STDERR.puts variant1
    if nvariants > 1
        bracket_index = variant2.index("]")
        variant2 = "#{variant2[0..bracket_index-1]}#{useradd}#{variant2[bracket_index..-1]}"
    end
    #STDERR.puts variant2
    f_input.close
    return variant1, variant2
end

def read_author_freqs(maincorpus,exclude_anonyms=true)
    hash = Hash.new(0)
    f = "KorpApi\\authors\\#{maincorpus}\\all.tsv"
    f.each_line.with_index do |line,index|
        if index > 0
            line1 = line.strip.split("\t")
            if !(exclude_anonyms and ((maincorpus == "flashback" and line1[0] == "")  or (maincorpus == "familjeliv" and line1[0].include?("Anonym"))))
                hash[line1[0]] = line1[1].to_f
            end
        end
    end
    hash
end

def code_space(argument,direction)
    if direction == "code"
        argument = argument.gsub(" ","_SPACEENCODED_")
    elsif direction == "decode"
        argument = argument.gsub("_SPACEENCODED_", " ")
    end
    argument
end
