require 'uri'
require 'net/http'
require 'json'

def test(a)
    STDERR.puts a + 1
end

# Lengthen timeout in Net::HTTP
module Net
    class HTTP
        alias old_initialize initialize

        def initialize(*args)
            old_initialize(*args)
            @read_timeout = 5*60     # 5 minutes
        end
    end
end

def clean_query(dirty)
        dirty.gsub!("\"","\'") 
        dirty.gsub!(" ","+")
        clean = URI.escape(dirty)
        clean.gsub!("+&+","+%26+")
        return clean
    end
    
def process_query(clean, filename, corpus, counter, searchyear = "", searchmonth = "", verbose = true)
    uri = URI(clean)
    #uri.use_ssl = true

    res = ""
    Net::HTTP.start(uri.host, uri.port,:use_ssl => uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new uri
        res = http.request request # Net::HTTPResponse object
    end
    
    if verbose
        STDERR.puts res.code       # => '200'
        STDERR.puts res.message    # => 'OK'
        STDERR.puts res.class.name
    end
    
    if res.code.to_s != "502"
        j = File.open("#{filename}_#{corpus}_#{searchyear}_#{searchmonth}.json", "w:utf-8")
        
        j.puts res.body if res.is_a?(Net::HTTPSuccess)
        j.close
        file = File.read("#{filename}_#{corpus}_#{searchyear}_#{searchmonth}.json")
        data_hash = JSON.parse(file)
        if !data_hash["ERROR"].nil? or res.message != "OK"
            final_resmessage = "FAIL"
            STDERR.puts "Error in json"
        else
            final_resmessage = "OK"
        end
    else
        final_resmessage = "FAIL"
        STDERR.puts "Error 502"
    end

    return final_resmessage
end


def run_api_query(dirty_query, filename, corpus, errorlist, searchyear = "", searchmonth = "", try_until = 5)
    counter = 0
    clean = clean_query(dirty_query)
    STDERR.puts "Querying Korp..."
    STDERR.puts clean
    begin
        counter += 1
        STDERR.puts "Attempt #{counter}"
        resmessage = process_query(clean, filename, corpus, counter, searchyear, searchmonth)
        if resmessage == "OK"
            STDERR.puts "Successful, moving on"
            break
        end
        if counter == try_until
            errorlist.puts "#{corpus}\t#{searchyear}\t#{searchmonth}"
        end
    end until counter == try_until
end

