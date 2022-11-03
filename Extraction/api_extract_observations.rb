#load auxiliary scripts
require_relative 'net_tools.rb'
require_relative 'corpus_tools.rb'

#define a method to query Korp API
def execute_query(gran_spec, structs, filename, corpus, errorlist, limit, searchyear="", searchmonth="")
    dirty_query = "https://ws.spraakbanken.gu.se/ws/korp/v8/query?corpus=#{corpus}&end=#{limit}&default_within=sentence&default_context=1+sentence&cqp=([lex contains 'komma\.\.vb\.1' & msd = '.*PRS.*'#{gran_spec}] []{0,5} [pos = 'VB' & msd = '.*INF.*'])&show=msd,lemma,pos,deprel,dephead,ref,lemgram&show_struct=#{structs}"
    run_api_query(dirty_query, filename, corpus, errorlist, searchyear, searchmonth)
end

#determine which corpora to search in
corpora = read_corpus_label(ARGV[0])#read_corpus_label("flashback-all") #["twitter", "twitter-2015", "twitter-2016","twitter-2017"] 
#STDERR.puts corpora
maincorpus = get_maincorpus_from_label(ARGV[0])
STDERR.puts maincorpus

#create a directory where json output will be placed
output_dir = "Jsons_#{maincorpus}"
if !Dir.exist?(output_dir)
    Dir.mkdir(output_dir)
end

variable = "kommer_att"
filename = "#{output_dir}\\#{variable}_predictors"
limit = 1000000000
granularity = "month"

#create a log file to output errors
errorlist = File.open("errorlist_#{get_maincorpus(corpora[0])}.tsv", "w:utf-8")


#define the field name for the "date" parameter
if get_maincorpus(corpora[0]) == "twitter"
    datespec = "text_datetime"
elsif get_maincorpus(corpora[0]) == "press2"
    datespec = "text_year"
else
    datespec = "text_date"
end

corpora.each do |corpus|
    STDERR.puts corpus
    
    #define structural parameters
    structs = get_structs(maincorpus)

    #create a query depending on the chosen granularity level and execute it
    if granularity == "none"
        gran_spec = ""
        execute_query(gran_spec, structs, filename, corpus, errorlist, limit)
        
    elsif granularity == "year"
        years =  get_years(corpus,maincorpus,true)
        years.each do |searchyear|
            STDERR.puts searchyear
            gran_spec = " & _.#{datespec} = '#{searchyear}.*'"
            execute_query(gran_spec, structs, filename, corpus, errorlist, limit, searchyear)
        end #years 
    elsif granularity == "month"
        years = get_years(corpus,maincorpus,true)
        years.each do |searchyear|
            STDERR.puts searchyear
            months = ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"]
            months.each do |searchmonth|
                STDERR.puts searchyear, searchmonth 
                gran_spec = " & _.#{datespec} = '#{searchyear}-#{searchmonth}.*'"
                execute_query(gran_spec, structs, filename, corpus, errorlist, limit, searchyear, searchmonth)
            end #months
        end #years 
    end
end



