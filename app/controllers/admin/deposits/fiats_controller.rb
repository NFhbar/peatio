require_dependency 'admin/deposits/base_controller'

module Admin
  module Deposits
    class FiatsController < BaseController
      def index
        q = ::Deposits::Fiat.where(currency: currency)
        @latest_deposits = q.includes(:member).where('created_at <= ?', 1.day.ago).order('id DESC')
        @all_deposits    = q.includes(:member).where('created_at > ?', 1.day.ago).order('id DESC')
      end

      def new
        @deposit = ::Deposits::Fiat.new
      end

      def show
        @deposit = ::Deposits::Fiat.where(currency: currency).find(params[:id])
        flash.now[:notice] = t('.notice') if @deposit.aasm_state.accepted?
      end

      def create
        @deposit = ::Deposits::Fiat.new(deposit_params)
        if @deposit.save
          redirect_to admin_deposit_index_url(params[:currency])
        else
          flash[:alert] = @deposit.errors.full_messages.first
          render :new
        end
      end

      def update
        @deposit = ::Deposits::Fiat.where(currency: currency).find(params[:id])
        params   = self.params.require(:deposits_fiat).permit(:txid)

        if params[:txid].blank?
          flash[:alert] = 'Transaction ID is blank!'
          return redirect_to :back
        end

        @deposit.charge!(params[:txid])
        redirect_to :back
      end

    private

      def deposit_params
        params.require(:deposits_fiat).slice(:sn, :amount, :fund_uid, :fund_extra, :currency)
              .merge(currency: currency)
              .permit!
      end
    end
  end
end

