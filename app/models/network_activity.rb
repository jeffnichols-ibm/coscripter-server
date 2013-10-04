# (C) Copyright IBM Corp. 2010

class NetworkActivity
  attr_accessor :date,:person,:action,:procedure,:reps
  def initialize( date,person,action,procedure,reps=1)
    @person = person
    @date = date
    @action = action
    @procedure = procedure
    @reps = reps ;
  end

  def to_s 
    return "#{person.name}, #{action} #{(procedure.nil?)?"a private script":procedure.title} on #{date} "
  end
  
  def to_json(foo, bar)
    rep = {:person => person.name,:action=>action,:date=>date}
    if procedure.nil? 
      rep[:procedure] = {:title=>"private",:id=>-1}
    else
      rep[:procedure] = {:title=>procedure.title,:id=>procedure.id}
    end
    return rep.to_json 
  end
  
  def to_html
  end

end
