class OrderMailer < ApplicationMailer
  default from: "noreply@craftcommerce.example.com"

  def confirmation_email(order)
    @order = order
    @user = order.user
    mail(to: @user.email_address, subject: "【CraftCommerce】ご注文ありがとうございます (#{@order.order_number})")
  end
end
