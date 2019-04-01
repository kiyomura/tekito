class Symbol
  def call(*args, &block)
    if args.size > 0 || block.nil?.!
      -> arg {self.to_proc[arg, *args, &block]}
    else
      self.to_proc
    end
  end
end

class Object
  def _p(method) self.method(method).to_proc end
end

class String
  def camerize; self.sub(/^[a-z]/, &:upcase) end
end

CMD, BRANCH, SPASS, KPASS = ARGV
ALPHA_TAG = BRANCH # tag branch exclusive
#-------------------------------------------------------------------------------
# 設定項目
APK = 'app*.apk'
NOW = Time.now.strftime('%Y%m%d_%H%M')
NAME_CODE = "#{BRANCH}/release/"
DB_ROOT = "/kiyomura/apk/#{NOW}#{NAME_CODE}"
OUTPUT_DIR = './app/build/outputs'
TRAVIS_DIR = './.travis'
KEY_STORE = '#{TRAVIS_DIR}/hoge.keystore'
FLAVORS = ['dev', 'stage', 'real', 'real_ope']
TYPES = ['debug', 'release']
REJECT_TYPE_AT_SIGNING = 'Debug'
UP_CMD = "./dropbox_uploader.sh upload "

VARIANTS = FLAVORS
  .map(&:camerize)
  .map {|pre| TYPES.map(&:camerize).map(&pre._p(:+))}
  .flatten
SIGN_VARIANTS = VARIANTS.reject(&:end_with?.(REJECT_TYPE_AT_SIGNING))
TEST_TARGET = "connected#{VARIANTS[0]}AndroidTest"
#-------------------------------------------------------------------------------

def build_apk_command(variants)
  variants.map(&'./gradlew -s assemble'._p(:+)).join("\n")
end

def signing_apk_command(variants, spass, kpass)
end

def upload_apk_command(variants)
=begin
  variants
    .map {|v|
      Dir
        .glob("#{OUTPUT_DIR}/apk/#{v}/**/#{APK}")
        .map {|apk| "#{UP_CMD} #{OUTPUT_DIR}/apk/#{v}/#{apk} #{DB_ROOT}/signed/#{apk}"}
    }
    .join("\n")
=end
end

def upload_map_command(variants)
=begin
  d, f = ['mapping'] * 2; f += '.txt'
  variants
    .map {|v| "#{UP_CMD} #{OUTPUT_DIR}/#{d}/#{v}/#{f} #{DB_ROOT}/#{d}/#{v}/#{f}"}
    .join("\n")
=end
end

exec(
  case CMD
    when 'test'
      <<-EOS
        git checkout #{ALPHA_TAG}
        ./gradlew -s clean
        ./gradlew -s #{TEST_TARGET}
      EOS
    when 'send'
      <<-EOS
        #{build_apk_command(VARIANTS)}
        #{signing_apk_command(SIGN_VARIANTS, SPASS, KPASS)}
        #{upload_apk_command(VARIANTS)}
        #{upload_map_command(SIGN_VARIANTS)}
      EOS
    else
      'nothing to do'
  end.gsub(/ {2,}/, ' ').gsub(/^ /, '')
)
