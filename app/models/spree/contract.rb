class Spree::Contract < ActiveRecord::Base

  belongs_to :project

  has_attached_file :designer_sign,
                    styles: {},
                    default_style: :original,
                    path: 'signatures/designer_sign/:id/:style/:basename.:extension',
                    convert_options: { all: '-strip -auto-orient -colorspace sRGB' }

  has_attached_file :client_sign,
                    styles: {},
                    default_style: :original,
                    path: 'signatures/client_sign/:id/:style/:basename.:extension',
                    convert_options: { all: '-strip -auto-orient -colorspace sRGB' }


  def generate_and_send_contract(contract)
    pdf = WickedPdf.new.pdf_from_string(contract)
    save_path = Rails.root.join('public',"filename-#{Time.now.to_i}.pdf")
    File.open(save_path, 'wb') do |file|
      file << pdf
    end

    pdf_file = File.open(save_path,"r")

    images = []
    self.project.boards.each do |board|
      images << board.board_image.attachment.url(:large) if board.board_image.present?
    end

    if Spree::Mailers::ContractMailer.contract_email_with_pdf(self.project.email,self.project.user,save_path,images).deliver
      Spree::ProjectHistory.create(action: "contract_sent",project_id: self.project_id, pdf: pdf_file)
      File.delete(save_path) if File.exist?(save_path)
    end
  end

  def signed?
    self.designer_signed or self.designer_signed
  end

  def self.send_contract_email(email, template, subject, link)
    html_content = ''
    email = 'dniedzialkowski@netkodo.com' if Rails.env == "development"
    email = 'sam@scoutandnimble.com' if Rails.env == "staging"
    Rails.env == "development" ? dev ="<development>" : dev=""
    subject = "#{subject} #{dev}"
    m = Mandrill::API.new(MANDRILL_KEY)
    message = {
        :subject=> subject,
        :from_name=> "Jesse Bodine",
        :text=>"You have new question",
        :to=>[
            {
                :email=> email
            }
        ],
        :from_email=>"support@scoutandnimble.com",
        :track_opens => true,
        :track_clicks => true,
        :url_strip_qs => false,
        :signing_domain => "scoutandnimble.com",
        :merge_language => "handlebars",
        :merge_vars => [
            {
                :rcpt => email,
                :vars => [
                    {
                        :name => "subject",
                        :content => subject
                    },
                    {
                        :name => "link",
                        :content => link
                    }
                ]
            }
        ]
    }

    sending = m.messages.send_template(template, [{:name => 'main', :content => html_content}], message, true)
  end

end