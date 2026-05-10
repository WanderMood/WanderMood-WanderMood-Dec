import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import PartnersClient from "./PartnersClient";

type Props = { params: Promise<{ locale: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "partners" });
  return {
    title: t("meta.title"),
    description: t("meta.description"),
  };
}

export default function PartnersPage() {
  return <PartnersClient />;
}
