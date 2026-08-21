require "prawn"
require "stringio"

class ReceiptGenerationJob < ApplicationJob
  queue_as :default

  def perform(order_id)
    order = Order.find_by(id: order_id)
    return unless order

    job_log = JobLog.create!(
      job_type: "receipt_generation",
      status: "running",
      payload: { order_id: order.id, order_number: order.order_number }.to_json
    )

    begin
      pdf_data = generate_receipt_pdf(order)

      order.receipt.attach(
        io: StringIO.new(pdf_data),
        filename: "receipt_#{order.order_number}.pdf",
        content_type: "application/pdf"
      )

      if order.receipt.attached?
        order.update_column(:receipt_blob_key, order.receipt.blob.key)
      end

      Rails.logger.info "[ReceiptGenerationJob] Generated Japanese receipt PDF for Order ##{order.order_number}"

      job_log.update!(
        status: "completed",
        finished_at: Time.current
      )
    rescue => e
      Rails.logger.error "[ReceiptGenerationJob] Failed for Order ##{order.order_number}: #{e.message}"
      job_log.update!(
        status: "failed",
        payload: { error: e.message, backtrace: e.backtrace&.first(5) }.to_json,
        finished_at: Time.current
      )
      raise e
    end
  end

  private

  def generate_receipt_pdf(order)
    pdf = Prawn::Document.new(page_size: "A4", margin: 40)

    # Register Japanese font if available
    font_path = Rails.root.join("vendor/fonts/NotoSansJP.ttf").to_s
    has_jp_font = File.exist?(font_path)

    if has_jp_font
      pdf.font_families.update("NotoSansJP" => {
        normal: font_path,
        bold: font_path
      })
      pdf.font("NotoSansJP")
    else
      pdf.font("Helvetica")
    end

    # Title
    pdf.text has_jp_font ? "領 収 書" : "OFFICIAL RECEIPT", size: 24, style: :bold, align: :center
    pdf.move_down 15

    # Customer & Meta Information
    customer_name = order.user.name.presence || order.user.email_address
    if has_jp_font
      pdf.text "#{customer_name} 様", size: 14, style: :bold
      pdf.move_down 4
      pdf.text "注文番号: #{order.order_number}", size: 10, color: "333333"
      pdf.text "発行日時: #{order.created_at.strftime('%Y年%m月%d日 %H:%M')}", size: 9, color: "666666"
    else
      pdf.text "Billed To: #{customer_name.encode('ASCII', invalid: :replace, undef: :replace, replace: '')}", size: 12, style: :bold
      pdf.text "Order Number: #{order.order_number}", size: 10
      pdf.text "Date: #{order.created_at.strftime('%Y-%m-%d %H:%M')}", size: 9, color: "666666"
    end

    pdf.move_down 10
    pdf.stroke_horizontal_rule
    pdf.move_down 10

    # Store Information
    if has_jp_font
      pdf.text "発行元: CraftCommerce オンラインストア", size: 10, style: :bold
      pdf.text "URL: https://craftcommerce.example.com", size: 9, color: "666666"
    else
      pdf.text "Issuer: CraftCommerce Online Store", size: 10, style: :bold
      pdf.text "URL: https://craftcommerce.example.com", size: 9, color: "666666"
    end

    pdf.move_down 10
    pdf.stroke_horizontal_rule
    pdf.move_down 20

    # Total Box
    formatted_total = order.total_amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    pdf.fill_color "F3F4F6"
    pdf.fill_rectangle [0, pdf.cursor], pdf.bounds.width, 42
    pdf.fill_color "111827"
    
    total_label = has_jp_font ? "領収金額:  ¥#{formatted_total} (税込・決済完了)" : "Total Amount: JPY #{formatted_total} (PAID IN FULL)"
    pdf.text_box total_label, at: [14, pdf.cursor - 13], size: 15, style: :bold

    pdf.move_down 60

    # Order Line Items Section
    pdf.text has_jp_font ? "ご注文明細" : "Order Line Items", size: 13, style: :bold
    pdf.move_down 8

    order.order_items.includes(:product).each_with_index do |item, idx|
      product_title = if has_jp_font
        item.product&.name || "商品 ##{item.product_id}"
      else
        (item.product&.name || "Product ##{item.product_id}").encode("ASCII", invalid: :replace, undef: :replace, replace: "")
      end

      unit_price = item.price_at_purchase.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
      subtotal = item.subtotal.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse

      item_header = "#{idx + 1}. #{product_title}"
      item_details = if has_jp_font
        "    数量: #{item.quantity} 点  |  単価: ¥#{unit_price}  |  小計: ¥#{subtotal}"
      else
        "    Qty: #{item.quantity}  x  Price: JPY #{unit_price}  =  Subtotal: JPY #{subtotal}"
      end

      pdf.text item_header, size: 11, style: :bold, color: "111827"
      pdf.text item_details, size: 10, color: "4B5563"
      pdf.move_down 6
    end

    pdf.move_down 20
    pdf.stroke_horizontal_rule
    pdf.move_down 15

    # Footer note
    footer_text = has_jp_font ? "この度は CraftCommerce をご利用いただき誠にありがとうございます。" : "Thank you for shopping with CraftCommerce!"
    pdf.text footer_text, size: 10, align: :center, color: "6B7280"

    pdf.render
  end
end
