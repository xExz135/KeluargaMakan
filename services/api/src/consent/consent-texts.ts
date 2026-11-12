/**
 * Consent texts served by `GET /v1/consent-texts/{purpose}` (ACC-08, SET-03,
 * SET-10). The client shows these and sends the version back with the
 * decision; every consent record stores that version, so the final, legally
 * reviewed texts are a content swap with a new version (QUESTIONS #23, T-090).
 *
 * DRAFT: needs legal review. The wording comes from the ux-designer's copy
 * deck (`consent.rules.*`, `consent.full.*`, `family.guardian.*`,
 * `consent.child.note`), all marked DRAFT there. `isDraft` stays true until
 * legal approves a version. Agents do not write legal text: the "full text"
 * section is the copy deck's placeholder for the legal team.
 */

export type ConsentPurpose = "health_data" | "guardian_confirmation";
export type ConsentLanguage = "id" | "en";

export interface ConsentTextSection {
  readonly heading: string;
  readonly body: string;
}

export interface ConsentTextContent {
  readonly purpose: ConsentPurpose;
  readonly version: string;
  readonly effectiveDate: string;
  readonly isDraft: boolean;
  readonly languages: Readonly<
    Record<
      ConsentLanguage,
      { readonly title: string; readonly sections: readonly ConsentTextSection[] }
    >
  >;
}

const HEALTH_DATA: ConsentTextContent = {
  purpose: "health_data",
  version: "health-data-draft-1",
  effectiveDate: "2026-11-12",
  isDraft: true,
  languages: {
    id: {
      title: "Persetujuan menyimpan aturan makan",
      sections: [
        {
          heading: "Yang disimpan",
          body: "Alergi, aturan makan (seperti halal) dan pantangan dari dokter yang Anda pilih.",
        },
        {
          heading: "Untuk apa",
          body: "Supaya Cek Aman bisa memeriksa setiap resep untuk anggota keluarga ini.",
        },
        {
          heading: "Di mana",
          body: "Di server KeluargaMakan, dikunci dengan kunci terpisah. Tidak dikirim bersama nama ke layanan AI.",
        },
        {
          heading: "Menarik izin",
          body: "Anda bisa menarik izin kapan saja di Pengaturan. Aturan makan lalu berhenti dipakai dan dihapus.",
        },
        {
          heading: "Penjelasan lengkap",
          body: "[DRAFT: teks lengkap dari tim legal. Harus mencakup: data apa, tujuan, dasar pemrosesan menurut UU PDP, lokasi penyimpanan, siapa yang bisa mengakses, berapa lama disimpan, hak menarik izin dan akibatnya, kontak.]",
        },
      ],
    },
    en: {
      title: "Consent to save food rules",
      sections: [
        {
          heading: "What we save",
          body: "The allergies, food rules (like halal) and doctor's restrictions you picked.",
        },
        {
          heading: "Why",
          body: "So Cek Aman can check every recipe for this family member.",
        },
        {
          heading: "Where",
          body: "On KeluargaMakan's servers, locked with a separate key. Never sent with a name to AI services.",
        },
        {
          heading: "Withdrawing",
          body: "You can withdraw this any time in Settings. The food rules then stop being used and are deleted.",
        },
        {
          heading: "Full explanation",
          body: "[DRAFT: full text from legal. Must cover: what data, purpose, legal basis under UU PDP, storage location, who can access it, retention, the right to withdraw and its effect, contact.]",
        },
      ],
    },
  },
};

const GUARDIAN_CONFIRMATION: ConsentTextContent = {
  purpose: "guardian_confirmation",
  version: "guardian-confirmation-draft-1",
  effectiveDate: "2026-11-12",
  isDraft: true,
  languages: {
    id: {
      title: "Konfirmasi orang tua atau wali",
      sections: [
        {
          heading: "Data anak",
          body: "Data anak di bawah 18 tahun kami jaga lebih ketat. Data kesehatan anak tidak disimpan kecuali Anda izinkan, dan tidak pernah dipakai untuk pemasaran.",
        },
        {
          heading: "Konfirmasi",
          body: "Saya orang tua atau wali anak ini, dan saya yang mengatur data anak ini di aplikasi ini.",
        },
      ],
    },
    en: {
      title: "Parent or guardian confirmation",
      sections: [
        {
          heading: "Children's data",
          body: "We protect data about children under 18 more strictly. A child's health data is not saved unless you allow it, and it's never used for marketing.",
        },
        {
          heading: "Confirmation",
          body: "I am this child's parent or guardian, and I manage this child's data in this app.",
        },
      ],
    },
  },
};

export const CONSENT_TEXTS: Readonly<Record<ConsentPurpose, ConsentTextContent>> = Object.freeze({
  health_data: HEALTH_DATA,
  guardian_confirmation: GUARDIAN_CONFIRMATION,
});

/** The current text version for a purpose. A decision must quote it (409 `consent_text_outdated`). */
export function currentConsentVersion(purpose: ConsentPurpose): string {
  return CONSENT_TEXTS[purpose].version;
}
