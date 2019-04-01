require 'date'
require 'time'

# 200履歴とればさすがに1件は alpha タグついたものあるでしょう
MAX_OF_SEARCHING_HISTORY = 200

class Integer # 読みやすくするためだけ
  def hours; self * 60 * 60 end
  def days; self end
end

class Symbol
  def call(*args) -> rcvr {self.to_proc[rcvr, *args]} end
end

def cron?
  ENV['TRAVIS_EVENT_TYPE'] == 'cron'
end

def with_buildable_tag?
  /^(.{19}) \(.*(alpha_[^,]+).*\)$/ =~ <<-`EOS`
      git log --oneline -n #{MAX_OF_SEARCHING_HISTORY} --decorate \
          --pretty=format:'%cd%d' --date=format:'%Y/%m/%d %H:%M:%S'
    EOS
      .split("\n")
      .select(&:include?.('tag: alpha_'))
      .first

  if Regexp.last_match
    (Date.today - 7.days).to_time + 18.hours < Time.parse(Regexp.last_match[1]) &&
      yield(Regexp.last_match[2])
    true
  else
    false
  end
end

cron? && with_buildable_tag? {|tag| print tag}
