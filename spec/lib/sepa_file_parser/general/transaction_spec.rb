# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SepaFileParser::Transaction do
  context 'version 2' do
    let(:camt)       { SepaFileParser::File.parse('spec/fixtures/camt053/valid_example.xml') }
    let(:statements) { camt.statements }
    let(:ex_stmt)    { statements[0] }
    let(:entries)  { ex_stmt.entries }
    let(:ex_entry) { entries[0] }
    let(:transactions)   { ex_entry.transactions }
    let(:ex_transaction) { transactions[0] }

    specify { expect(transactions).to all(be_kind_of(described_class)) }

    context '#amount' do
      specify { expect(ex_transaction.amount).to be_kind_of(BigDecimal) }
      specify { expect(ex_transaction.amount).to eq(BigDecimal('2')) }
      specify { expect(ex_transaction.amount_in_cents).to eq(200) }

      context 'AmtDtls/InstdAmt' do
        let(:camt) { SepaFileParser::File.parse('spec/fixtures/camt053/valid_example_with_instdamt.xml') }
        specify { expect(ex_transaction.amount).to eq(BigDecimal('4500')) }
        specify { expect(ex_transaction.amount_in_cents).to eq(450000) }
      end
    end

    context '#currency' do
      specify { expect(ex_transaction.currency).to eq('EUR') }

      context 'AmtDtls/InstdAmt' do
        let(:camt) { SepaFileParser::File.parse('spec/fixtures/camt053/valid_example_with_instdamt.xml') }
        specify { expect(ex_transaction.currency).to eq('CHF') }
      end
    end

    specify { expect(ex_transaction.currency).to eq('EUR') }
    specify { expect(ex_transaction.debit).to eq(true) }
    specify { expect(ex_transaction.debit?).to eq(ex_transaction.debit) }
    specify { expect(ex_transaction.credit?).to eq(false) }
    specify { expect(ex_transaction.sign).to eq(-1) }

    specify { expect(ex_transaction.creditor).to be_kind_of(SepaFileParser::Creditor) }
    specify { expect(ex_transaction.debitor).to be_kind_of(SepaFileParser::Debitor) }
    specify { expect(ex_transaction.postal_address).to be_kind_of(SepaFileParser::PostalAddress) }
    specify { expect(ex_transaction.remittance_information)
      .to eq("TEST BERWEISUNG MITTELS BLZUND KONTONUMMER - DTA") }
    specify { expect(ex_transaction.iban).to eq("DE09300606010012345671") }
    specify { expect(ex_transaction.bic).to eq("DAAEDEDDXXX") }
    specify { expect(ex_transaction.swift_code).to eq("NTRF") }
    specify { expect(ex_transaction.reference).to eq("") }
    specify { expect(ex_transaction.bank_reference).to eq("BankReference") }
    specify { expect(ex_transaction.end_to_end_reference).to eq("EndToEndReference") }
    specify { expect(ex_transaction.mandate_reference).to eq("MandateReference") }
    specify { expect(ex_transaction.transaction_id).to eq("UniqueTransactionId") }
    specify { expect(ex_transaction.creditor_identifier).to eq("CreditorIdentifier") }
    specify { expect(ex_transaction.payment_information).to eq("PaymentIdentification") }
    specify {
      expect(ex_transaction.additional_information).to eq("AdditionalTransactionInformation")
    }
    specify { expect(ex_transaction.xml_data).to_not be_nil }
  end

  context 'version 4' do
    let(:camt)       { SepaFileParser::File.parse('spec/fixtures/camt053/valid_example_v4.xml') }
    let(:statements) { camt.statements }
    let(:ex_stmt)    { statements[0] }
    let(:entries)  { ex_stmt.entries }
    let(:ex_entry) { entries[6] }
    let(:transactions)   { ex_entry.transactions }
    let(:ex_transaction) { transactions[0] }

    context '#amount' do
      specify { expect(ex_transaction.amount).to be_kind_of(BigDecimal) }
      specify { expect(ex_transaction.amount).to eq(BigDecimal('100')) }
      specify { expect(ex_transaction.amount_in_cents).to eq(10000) }
    end

    context '#reason_code' do
      let(:ex_entry) { entries[12] }

      specify { expect(ex_transaction.reason_code).to eq("MD06") }
    end

    specify { expect(ex_transaction.name).to eq("Hans Kaufmann") }
    specify { expect(ex_transaction.creditor_reference).to eq("CreditorReference") }
  end

  context 'version 8' do
    let(:camt)       { SepaFileParser::File.parse('spec/fixtures/camt053/valid_example_v8.xml') }
    let(:statements) { camt.statements }
    let(:ex_stmt)    { statements[0] }
    let(:entries)  { ex_stmt.entries }
    let(:ex_entry) { entries[1] }
    let(:transactions)   { ex_entry.transactions }
    let(:ex_transaction) { transactions[0] }

    context '#amount' do
      specify { expect(ex_transaction.amount).to be_kind_of(BigDecimal) }
      specify { expect(ex_transaction.amount).to eq(BigDecimal('88.85')) }
      specify { expect(ex_transaction.amount_in_cents).to eq(8885) }
    end

    context 'transaction with different currency' do
      let(:ex_transaction) { transactions[0] }
      let(:ex_entry) { entries[2] }

      context '#amount' do
        specify { expect(ex_transaction.amount).to be_kind_of(BigDecimal) }
        specify { expect(ex_transaction.amount).to eq(BigDecimal('20.97')) }
        specify { expect(ex_transaction.amount_in_cents).to eq(2097) }
      end

      context '#original_currency_amount' do
        specify { expect(ex_transaction.original_currency_amount).to be_kind_of(BigDecimal) }
        specify { expect(ex_transaction.original_currency_amount).to eq(BigDecimal('19.69')) }
      end

      specify { expect(ex_transaction.currency).to eq('EUR') }
      specify { expect(ex_transaction.original_currency).to eq('CHF') }
      specify { expect(ex_transaction.exchange_rate).to eq('0.9433') }
    end

    specify { expect(ex_transaction.name).to eq("Finanz AG") }
    specify { expect(ex_transaction.creditor_reference).to eq("RF38000000000000000000552") }
    specify { expect(ex_transaction.swift_code).to eq("A90") }
    specify { expect(ex_transaction.bank_reference).to eq("0123171DO5126811") }
    specify { expect(ex_transaction.end_to_end_reference).to eq("435A9287E088BDB1D97FAABD181C70C8") }

    context "#remittance_information" do
      let(:ex_entry) { entries[0] }
      let(:transactions)   { ex_entry.transactions }
      let(:ex_transaction) { transactions[0] }

    specify { expect(ex_transaction.remittance_information).to eq("INVOICE R77561") }
    end
  end

  context 'missing creditor identifier' do
    let(:camt)       { SepaFileParser::File.parse('spec/fixtures/camt053/missing_creditor_identifier.xml') }
    let(:statements) { camt.statements }
    let(:ex_stmt)    { statements[0] }
    let(:entries)  { ex_stmt.entries }
    let(:ex_entry) { entries[0] }
    let(:transactions)   { ex_entry.transactions }
    let(:ex_transaction) { transactions[0] }

    specify { expect(ex_transaction.creditor_identifier).to eq(nil) }
  end
end
