BRANCH = ARGV[0]
#-------------------------------------------------------------------------------
# 設定項目
APK = 'app*.apk'
NOW = Time.now.strftime("%Y%m%d_%H%M')
NAME_CODE = "#{BRANCH}/release/"
DB_ROOT = "/kiyomura/apk/#{NOW}#{NAME_CODE}"
OUTPUT_DIR = './app/build/outputs'
TRAVIS_DIR = '.travis'
KEY_STORE = '#{TRAVIS_DIR}/hoge.keystore'
FLAVORS = ['dev', 'stage', 'real', 'real_ope']
TYPES = ['debug', 'release']
REJECT_TYPE_AT_SIGNING = 'Debug'
UPCMD = "./dropbox_uploader.sh upload "
#-------------------------------------------------------------------------------

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
  def to_p(method) self.method(method).to_proc end
end

VARIANTS = FLAVORS \
  .map {|pre| TYPES.map(&:sub.(/^[a-z]/, &:upcase)).map(&pre.to_p(:+))} \
  .flatten

SIGN_VARIANTS = VARIANTS.reject(&:end_with?.(REJECT_TYPE_AT_SIGNING))

def build_apk_command(variants)
  asmcmd = './gradlew -s assemble'
  variants.map {|v| asmcmd + v.gsub(/^[a-z]|_[a-z]/, &:upcase)}.join("\n")
end

def signing_apk_command(spass: sp, kpass: kp, variants: vs)
end

def upload_apk_command(variants)
=begin
  variants
    .map {|v|
      Dir
        .glob("#{OUTPUT_DIR}/apk/#{v}/**/#{APK}")
        .map {|apk| "#{UPCMD} #{OUTPUT_DIR}/apk/#{v}/#{apk} #{DB_ROOT}/signed/#{apk}"}
    }
    .join("\n")
=end
end

def upload_map_command(variants)
=begin
  d, f = ['mapping'] * 2; f += '.txt'
  variants
    .map {|v| "#{UPCMD} #{OUTPUT_DIR}/#{d}/#{v}/#{f} #{DB_ROOT}/#{d}/#{v}/#{f}"}
    .join("\n")
=end
end

system <<-EOS
  #{build_apk_command(VARIANTS)}
  #{signing_apk_command(variants: SIGN_VARIANTS, spass: ARGV[1], kpass: ARGV[2])}
  #{upload_apk_command(VARIANTS)}
  #{upload_map_command(SIGN_VARIANTS)}
EOS.lstrip
