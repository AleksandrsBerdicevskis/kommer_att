f = File.open("confusion_table_APPENDIX.tsv","r:utf-8")
metric = "ba"
o = File.open("q1_approacha_#{metric}.tsv","w:utf-8")
o.puts "split\tcorpus\tmodel\tfractional_polynomial_variant\t#{metric}_train\t#{metric}_test\taic"
def balanced_accuracy(tp, tn, fp, fn)
    sensitivity = tp / (tp + fn)
    specificity = tn / (fp + tn)
    balanced_accuracy = (sensitivity + specificity) / 2
    return balanced_accuracy
end

def mcc(tp, tn, fp, fn)
    denominator = Math.sqrt((tp+fp) * (tp+fn) * (tn+fp) * (tn+fn))
    if denominator == 0
        mcc = 0
    else
        mcc = (tp*tn - fp*fn) / denominator
    end
    return mcc
end

#label = nil
best_ba_train = nil
best_label = nil
best_aic = nil
chosen_ba_test = nil
f.each_line.with_index do |line,index|
    if index > 0
        line2 = line.strip.split("\t")
        label = line2[0..2].join("-")
        poly = line2[4]
        #STDERR.puts label, poly
        if line2[3] == "yes"
            tp, tn, fp, fn = line2[5].to_f, line2[6].to_f, line2[7].to_f, line2[8].to_f
            ttp, ttn, tfp, tfn = line2[9].to_f, line2[10].to_f, line2[11].to_f, line2[12].to_f
            if metric == "ba"
                ba_train  = balanced_accuracy(tp, tn, fp, fn)
                ba_test = balanced_accuracy(ttp, ttn, tfp, tfn)
            elsif metric == "mcc"
                ba_train  = mcc(tp, tn, fp, fn)
                ba_test = mcc(ttp, ttn, tfp, tfn)
            end

            aic = line2[-1].to_i
            if best_label.nil?
                best_ba_train = ba_train.clone 
                best_label = "#{label}-#{poly}"
                best_aic = aic.clone
                chosen_ba_test = ba_test.clone
            else     
                #STDERR.puts best_ba_train
                if ba_train > best_ba_train
                    best_ba_train = ba_train.clone 
                    best_label = "#{label}-#{poly}"
                    best_aic = aic.clone
                    chosen_ba_test = ba_test.clone
                elsif ba_train == best_ba_train
                    if aic < best_aic
                        best_label = "#{label}-#{poly}"
                        best_aic = aic.clone
                        chosen_ba_test = ba_test.clone
                    elsif aic == best_aic
                        best_label = [best_label, "#{label}-#{poly}"].flatten
                        chosen_ba_test = [chosen_ba_test, ba_test].flatten
                    end
                end
            end
        end
        if poly == "3"
            if best_label.is_a?(Array)
                guess = rand(best_label.length)
                best_label = best_label[guess]
                chosen_ba_test = chosen_ba_test[guess]
            end
            
            o.puts "#{best_label.gsub("-","\t")}\t#{best_ba_train}\t#{chosen_ba_test}\t#{best_aic}"
            #label = nil
            best_ba_train = nil
            best_label = nil
            best_aic = nil
            chosen_ba_test = nil
        end
    end

end